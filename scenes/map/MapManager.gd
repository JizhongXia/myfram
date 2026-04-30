extends Node2D

## 世界：整图海水 + 浮在海面的草地岛（轻微上下摆动）+ 丛林树 + 农田（翻土 / 播种 / 生长 / 收获）

const TILE_SIZE := 64
const MAP_W := 48
const MAP_H := 32

## Sprout Lands Grass.png：主草地 (2,4) 为纯色块，远景像「一片绿」无草地质感。
## 岛面使用不透明且方差高的草地格混合；(5,3) 等半透明格仍会透出底色，禁止使用。
const GRASS_FIELD: Array[Vector2i] = [
	Vector2i(7, 6), Vector2i(3, 7), Vector2i(2, 7), Vector2i(6, 6), Vector2i(6, 7), Vector2i(7, 7),
]
const GRASS_FIELD_BRIGHT: Array[Vector2i] = [
	Vector2i(4, 4), Vector2i(5, 4), Vector2i(4, 5), Vector2i(5, 5),
]

const SRC_WATER := 0
const SRC_GRASS := 1
const SRC_SOIL := 2

const SOIL_ATLAS := Vector2i(0, 0)

## ---------------------------------------------------------------------------
## 种植规则（与下方 _try_farm_interact / _till_cell / _try_plant / _harvest_cell 一致）
##
## 1. 田区：必须在岛上、且不在丛林心；矩形格范围（含边界）由 FARM_CELL_* 定义。
## 2. 交互键：E / 手柄 A（`interact`）；背包打开时不处理。
## 3. 空地（无作物、无田土格）：第一次交互 → 翻土（消耗无，铺 soil 瓦片）。
## 4. 已翻土、无作物：有对应种子则播种并消耗 1 粒；无任何种子则提示。
## 5. 播种优先级：同时有玉米种子与番茄种子时，优先种玉米。
## 6. 已翻土且已有作物：未成熟（stage < CROP_STAGE_MATURE）→ 仅提示；成熟 → 收获，
##    清空该格作物与田土，果实入包（数量见 HARVEST_*）。
## 7. 生长：每格独立计时；每 GROW_SEC_STAGE 秒升一阶，0→1→2→3 可收。
## ---------------------------------------------------------------------------
const FARM_CELL_MIN := Vector2i(MAP_W / 2 - 7, MAP_H / 2 + 1)
const FARM_CELL_MAX := Vector2i(MAP_W / 2 + 9, MAP_H / 2 + 13)
const SEED_COST_PER_PLANT := 1
## 作物阶段 0..3，共 4 帧；达到 CROP_STAGE_MATURE 可收获。
const CROP_STAGE_MATURE := 3
const GROW_SEC_STAGE := 5.0
const HARVEST_CORN_MIN := 1
const HARVEST_CORN_MAX := 2
const HARVEST_TOMATO_MIN := 1
const HARVEST_TOMATO_MAX := 2

## 岛屿相对海面的垂直起伏（像素）
const ISLAND_BOB_AMPLITUDE := 5.0
const ISLAND_BOB_SPEED := 1.15

@onready var _ocean_backdrop: Node2D = $OceanBackdrop
@onready var _ocean_fill: Polygon2D = $OceanBackdrop/Fill
@onready var _water_layer: TileMapLayer = $Water
@onready var _island_shadow: Polygon2D = $IslandShadow
@onready var _island_root: Node2D = $IslandRoot
@onready var _island_layer: TileMapLayer = $IslandRoot/Island
@onready var _jungle_root: Node2D = $IslandRoot/Jungle
@onready var _farm_soil: TileMapLayer = $IslandRoot/FarmSoil
@onready var _farm_crops: Node2D = $IslandRoot/Jungle/FarmCrops
@onready var _trees_root: Node2D = $IslandRoot/Jungle/Trees
@onready var _player: CharacterBody2D = $IslandRoot/Jungle/Player

var _tile_set: TileSet
var _water_frame: int = 0
var _water_tick: float = 0.0
const WATER_ANIM_SEC := 0.18
var _bob_time: float = 0.0

var _rng := RandomNumberGenerator.new()

var _tex_tree_big: ImageTexture
var _tex_tree_small: ImageTexture

## cell -> { "id": "corn"|"tomato", "stage": 0..3, "grow": float }
var _crops: Dictionary = {}
var _corn_frames: Array[Texture2D] = []
var _tomato_frames: Array[Texture2D] = []


func _ready() -> void:
	_rng.randomize()
	_tex_tree_big = _load_image_texture("res://assets/sprout-lands/graphics/objects/tree_medium.png")
	_tex_tree_small = _load_image_texture("res://assets/sprout-lands/graphics/objects/tree_small.png")
	_load_crop_frames()

	_tile_set = _build_tileset()
	_water_layer.tile_set = _tile_set
	_island_layer.tile_set = _tile_set
	_farm_soil.tile_set = _tile_set
	# 与素材像素对齐，草地/海水格边缘更清晰（否则远距离缩放像糊成一片色块）
	_water_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_island_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_farm_soil.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_setup_ocean_backdrop()
	_setup_island_shadow()
	_paint_world()

	_jungle_root.y_sort_enabled = true
	_farm_crops.y_sort_enabled = true
	_trees_root.y_sort_enabled = true

	_spawn_player_on_island()
	_seed_demo_inventory()

	print("Island map + farm plot: E / 手柄 A 翻土·播种·收获（规则见 MapManager.gd 顶部注释）。")


func _load_crop_frames() -> void:
	for i in 4:
		var t := _load_image_texture("res://assets/sprout-lands/graphics/fruit/corn/%d.png" % i)
		if t:
			_corn_frames.append(t)
	for i in 4:
		var t2 := _load_image_texture("res://assets/sprout-lands/graphics/fruit/tomato/%d.png" % i)
		if t2:
			_tomato_frames.append(t2)


func _load_image_texture(res_path: String) -> ImageTexture:
	var img := Image.new()
	if img.load(res_path) != OK:
		push_error("MapManager: could not load image: %s" % res_path)
		return null
	return ImageTexture.create_from_image(img)


func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var strip := Image.create(TILE_SIZE * 4, TILE_SIZE, false, Image.FORMAT_RGBA8)
	for i in 4:
		var path := "res://assets/sprout-lands/graphics/water/%d.png" % i
		var frame := Image.new()
		if frame.load(path) != OK:
			push_error("MapManager: water frame missing: %s" % path)
			continue
		strip.blit_rect(frame, Rect2i(0, 0, TILE_SIZE, TILE_SIZE), Vector2i(i * TILE_SIZE, 0))
	var water_tex := ImageTexture.create_from_image(strip)
	var water_src := TileSetAtlasSource.new()
	water_src.texture = water_tex
	water_src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	ts.add_source(water_src, SRC_WATER)

	var grass_tex := _load_image_texture("res://assets/sprout-lands/graphics/environment/Grass.png")
	if grass_tex:
		var grass_src := TileSetAtlasSource.new()
		grass_src.texture = grass_tex
		grass_src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		ts.add_source(grass_src, SRC_GRASS)

	var soil_tex := _load_image_texture("res://assets/sprout-lands/graphics/soil/soil.png")
	if soil_tex:
		var soil_src := TileSetAtlasSource.new()
		soil_src.texture = soil_tex
		soil_src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		ts.add_source(soil_src, SRC_SOIL)

	return ts


func _setup_ocean_backdrop() -> void:
	var w := float(MAP_W * TILE_SIZE)
	var h := float(MAP_H * TILE_SIZE)
	_ocean_fill.polygon = PackedVector2Array([Vector2.ZERO, Vector2(w, 0.0), Vector2(w, h), Vector2(0.0, h)])


func _setup_island_shadow() -> void:
	# 与岛屿 footprint 接近的椭圆（原先 ry 过小会像一条深色“假陆地”横带）
	var ox := MAP_W / 2.0 * TILE_SIZE
	var oy := MAP_H / 2.0 * TILE_SIZE
	var rx := MAP_W * 0.36 * TILE_SIZE * 1.02
	var ry := MAP_H * 0.38 * TILE_SIZE * 0.82
	var pts := PackedVector2Array()
	var n := 48
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(Vector2(ox + cos(a) * rx, oy + sin(a) * ry + TILE_SIZE * 0.55))
	_island_shadow.polygon = pts


func _island_world_offset() -> Vector2:
	return _island_root.position


func _is_island(cx: int, cy: int) -> bool:
	var ox := MAP_W / 2.0
	var oy := MAP_H / 2.0
	var rx := MAP_W * 0.36
	var ry := MAP_H * 0.38
	var dx := (cx - ox) / rx
	var dy := (cy - oy) / ry
	return dx * dx + dy * dy <= 1.0


func _is_jungle(cx: int, cy: int) -> bool:
	if not _is_island(cx, cy):
		return false
	var ox := MAP_W / 2.0
	var oy := MAP_H / 2.0
	var rx := MAP_W * 0.22
	var ry := MAP_H * 0.24
	var dx := (cx - ox) / rx
	var dy := (cy - oy) / ry
	return dx * dx + dy * dy <= 1.0


func _is_farm_plot(cx: int, cy: int) -> bool:
	if not _is_island(cx, cy) or _is_jungle(cx, cy):
		return false
	return cx >= FARM_CELL_MIN.x and cx <= FARM_CELL_MAX.x and cy >= FARM_CELL_MIN.y and cy <= FARM_CELL_MAX.y


func _grass_atlas_for_cell(cx: int, cy: int) -> Vector2i:
	if _is_jungle(cx, cy):
		# 丛林也用不透明草地格，避免半透明格透出下层海水
		return GRASS_FIELD[_hash_i(cx, cy, 444) % GRASS_FIELD.size()]
	# 约 1/5 格用稍亮草地，打破单调
	if _hash_i(cx, cy, 503) % 5 == 0:
		return GRASS_FIELD_BRIGHT[_hash_i(cx, cy, 211) % GRASS_FIELD_BRIGHT.size()]
	return GRASS_FIELD[_hash_i(cx, cy, 709) % GRASS_FIELD.size()]


func _hash_i(x: int, y: int, salt: int) -> int:
	var v := x * 73856093 ^ y * 19349663 ^ salt * 83492791
	if v < 0:
		v = -v
	return v


func _paint_world() -> void:
	for y in MAP_H:
		for x in MAP_W:
			if _is_island(x, y):
				_island_layer.set_cell(Vector2i(x, y), SRC_GRASS, _grass_atlas_for_cell(x, y))
				if _is_jungle(x, y) and _rng.randf() < 0.24:
					_place_tree_sprite(x, y)
	_refresh_all_water_tiles()


func _refresh_all_water_tiles() -> void:
	for y in MAP_H:
		for x in MAP_W:
			if not _is_island(x, y):
				_water_layer.set_cell(Vector2i(x, y), SRC_WATER, Vector2i(_water_frame, 0))


func _place_tree_sprite(cx: int, cy: int) -> void:
	var tex: ImageTexture = _tex_tree_big if _rng.randf() < 0.55 else _tex_tree_small
	if tex == null:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = true
	var h := tex.get_height()
	spr.position = Vector2((cx + 0.5) * TILE_SIZE, (cy + 1.0) * TILE_SIZE - h * 0.5)
	spr.z_index = 2
	_trees_root.add_child(spr)


func _apply_water_frame() -> void:
	_refresh_all_water_tiles()


func _spawn_player_on_island() -> void:
	var cx := MAP_W / 2
	var cy := MAP_H / 2 - 4
	if not _is_island(cx, cy):
		for y in MAP_H:
			for x in MAP_W:
				if _is_island(x, y):
					cx = x
					cy = y
					break
			if _is_island(cx, cy):
				break
	var spawn := Vector2((cx + 0.5) * TILE_SIZE, (cy + 0.5) * TILE_SIZE)
	_player.global_position = _island_root.global_position + spawn


func _seed_demo_inventory() -> void:
	InventoryManager.add_item("apple", "苹果", 5)
	InventoryManager.add_item("corn", "玉米", 12)
	InventoryManager.add_item("wood", "木材", 30)
	InventoryManager.add_item("corn_seed", "玉米种子", 10)
	InventoryManager.add_item("tomato_seed", "番茄种子", 10)


func clamp_player_world_position(pos: Vector2) -> Vector2:
	var off := _island_world_offset()
	var local := pos - off
	var half := TILE_SIZE * 0.5
	local.x = clampf(local.x, half, MAP_W * TILE_SIZE - half)
	local.y = clampf(local.y, half, MAP_H * TILE_SIZE - half)
	var c := Vector2i(int(floor(local.x / TILE_SIZE)), int(floor(local.y / TILE_SIZE)))
	if c.x >= 0 and c.x < MAP_W and c.y >= 0 and c.y < MAP_H and _is_island(c.x, c.y):
		return local + off
	var hub := Vector2(MAP_W * 0.5 * TILE_SIZE, MAP_H * 0.5 * TILE_SIZE)
	var out := local
	for _i in 28:
		c = Vector2i(int(floor(out.x / TILE_SIZE)), int(floor(out.y / TILE_SIZE)))
		if c.x >= 0 and c.x < MAP_W and c.y >= 0 and c.y < MAP_H and _is_island(c.x, c.y):
			return out + off
		out = out.lerp(hub, 0.12)
	return out + off


func _unhandled_input(event: InputEvent) -> void:
	if InventoryManager.player_input_blocked:
		return
	if event.is_action_pressed(&"interact"):
		_try_farm_interact()
		get_viewport().set_input_as_handled()


func _player_cell() -> Vector2i:
	var o := _island_world_offset()
	var p := _player.global_position - o
	return Vector2i(int(floor(p.x / TILE_SIZE)), int(floor(p.y / TILE_SIZE)))


func _try_farm_interact() -> void:
	var cell := _player_cell()
	if not _is_farm_plot(cell.x, cell.y):
		print("[农田] 仅岛南侧矩形田区可耕种（格范围 x=%d..%d, y=%d..%d，且非丛林）。" % [
			FARM_CELL_MIN.x, FARM_CELL_MAX.x, FARM_CELL_MIN.y, FARM_CELL_MAX.y,
		])
		return

	if _crops.has(cell):
		var d: Dictionary = _crops[cell]
		var st: int = int(d["stage"])
		if st >= CROP_STAGE_MATURE:
			_harvest_cell(cell, str(d["id"]))
		else:
			print("[农田] 作物生长中（阶段 %d/%d，每阶段约 %.0f 秒）。" % [
				st, CROP_STAGE_MATURE, GROW_SEC_STAGE,
			])
		return

	if _farm_soil.get_cell_source_id(cell) != -1:
		_try_plant(cell)
		return

	_till_cell(cell)


func _till_cell(cell: Vector2i) -> void:
	if _farm_soil.get_cell_source_id(cell) != -1:
		print("[农田] 此处已是耕地，无需再翻土。")
		return
	_farm_soil.set_cell(cell, SRC_SOIL, SOIL_ATLAS)
	print("[农田] 已翻土 (%d,%d)。下一步：在背包中备种子后按 E 播种。" % [cell.x, cell.y])


func _try_plant(cell: Vector2i) -> void:
	if _crops.has(cell):
		print("[农田] 该格已有作物。")
		return
	var crop_id := ""
	var disp := ""
	# 规则：两种种子都有时优先玉米。
	if InventoryManager.count_item("corn_seed") > 0:
		crop_id = "corn"
		disp = "玉米"
	elif InventoryManager.count_item("tomato_seed") > 0:
		crop_id = "tomato"
		disp = "番茄"
	else:
		print("[农田] 无法播种：需要背包中有「玉米种子」或「番茄种子」（每格消耗 %d）。" % SEED_COST_PER_PLANT)
		return
	var seed_key := crop_id + "_seed"
	if not InventoryManager.consume_item(seed_key, SEED_COST_PER_PLANT):
		print("[农田] 种子消耗失败（背包异常）。")
		return
	_crops[cell] = { "id": crop_id, "stage": 0, "grow": 0.0 }
	_refresh_crop_visual(cell)
	print("[农田] 已播种：%s（消耗 %s ×%d）。" % [disp, seed_key, SEED_COST_PER_PLANT])


func _harvest_cell(cell: Vector2i, crop_id: String) -> void:
	var name_key := "%d_%d" % [cell.x, cell.y]
	var spr: Node = _farm_crops.get_node_or_null(name_key)
	if spr:
		spr.queue_free()
	_crops.erase(cell)
	_farm_soil.erase_cell(cell)
	var qty := 0
	if crop_id == "corn":
		qty = _rng.randi_range(HARVEST_CORN_MIN, HARVEST_CORN_MAX)
		InventoryManager.add_item("corn", "玉米", qty)
	elif crop_id == "tomato":
		qty = _rng.randi_range(HARVEST_TOMATO_MIN, HARVEST_TOMATO_MAX)
		InventoryManager.add_item("tomato", "番茄", qty)
	print("[农田] 收获完成（%s ×%d）。该格已清空，可再次翻土。" % [crop_id, qty])


func _refresh_crop_visual(cell: Vector2i) -> void:
	if not _crops.has(cell):
		return
	var d: Dictionary = _crops[cell]
	var crop_id: String = str(d["id"])
	var st: int = mini(int(d["stage"]), CROP_STAGE_MATURE)
	var frames: Array = _corn_frames if crop_id == "corn" else _tomato_frames
	if frames.is_empty():
		return
	var tex: Texture2D = frames[mini(st, frames.size() - 1)]
	var name_key := "%d_%d" % [cell.x, cell.y]
	var spr: Sprite2D = _farm_crops.get_node_or_null(name_key) as Sprite2D
	if spr == null:
		spr = Sprite2D.new()
		spr.name = name_key
		spr.centered = true
		spr.z_index = 3
		_farm_crops.add_child(spr)
	spr.texture = tex
	var h := tex.get_height()
	spr.position = Vector2((cell.x + 0.5) * TILE_SIZE, (cell.y + 1.0) * TILE_SIZE - h * 0.5)


func _process(delta: float) -> void:
	_bob_time += delta
	var bob := sin(_bob_time * ISLAND_BOB_SPEED) * ISLAND_BOB_AMPLITUDE + sin(_bob_time * 0.41) * 1.2
	_island_root.position = Vector2(0.0, bob)

	_water_tick += delta
	if _water_tick >= WATER_ANIM_SEC:
		_water_tick = 0.0
		_water_frame = (_water_frame + 1) % 4
		_apply_water_frame()

	for cell: Vector2i in _crops.keys():
		var d: Dictionary = _crops[cell]
		if int(d["stage"]) >= CROP_STAGE_MATURE:
			continue
		d["grow"] = float(d["grow"]) + delta
		while float(d["grow"]) >= GROW_SEC_STAGE and int(d["stage"]) < CROP_STAGE_MATURE:
			d["grow"] = float(d["grow"]) - GROW_SEC_STAGE
			d["stage"] = int(d["stage"]) + 1
			_refresh_crop_visual(cell)
