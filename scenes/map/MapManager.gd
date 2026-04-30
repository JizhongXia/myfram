extends Node2D

## 世界：整图海水 + 浮在海面的草地岛（轻微上下摆动）+ 丛林树 + 农田（翻土 / 播种 / 生长 / 收获）

const TILE_SIZE := 64
const MAP_W := 48
const MAP_H := 32

## Sprout Lands Grass.png：Tiled 教程地图主草地 gid=43 → atlas (2,4)。变体须选不透明瓦片：(5,3) 等大量透明会透出视口灰底，看起来像没铺草。
const ATLAS_GRASS_MAIN := Vector2i(2, 4)
const ATLAS_GRASS_ALT := Vector2i(5, 4)
const ATLAS_GRASS_JUNGLE := Vector2i(4, 4)

const SRC_WATER := 0
const SRC_GRASS := 1
const SRC_SOIL := 2

const SOIL_ATLAS := Vector2i(0, 0)
const GROW_SEC_STAGE := 5.0

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

	_setup_ocean_backdrop()
	_setup_island_shadow()
	_paint_world()

	_jungle_root.y_sort_enabled = true
	_farm_crops.y_sort_enabled = true
	_trees_root.y_sort_enabled = true

	_spawn_player_on_island()
	_seed_demo_inventory()

	print("Island map + farm plot: E / 手柄 A 翻土·播种·收获。")


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
	# 与 _is_island 相同椭圆（格坐标），略压扁并下移，画在海面上表示浮岛投影
	var ox := MAP_W / 2.0 * TILE_SIZE
	var oy := MAP_H / 2.0 * TILE_SIZE
	var rx := MAP_W * 0.36 * TILE_SIZE * 1.06
	var ry := MAP_H * 0.38 * TILE_SIZE * 0.22
	var pts := PackedVector2Array()
	var n := 40
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(Vector2(ox + cos(a) * rx, oy + sin(a) * ry + TILE_SIZE * 0.35))
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
	return cx >= MAP_W / 2 - 7 and cx <= MAP_W / 2 + 9 and cy >= MAP_H / 2 + 1 and cy <= MAP_H / 2 + 13


func _paint_world() -> void:
	for y in MAP_H:
		for x in MAP_W:
			if _is_island(x, y):
				var atlas := ATLAS_GRASS_MAIN
				if _is_jungle(x, y):
					atlas = ATLAS_GRASS_JUNGLE if _rng.randf() > 0.35 else ATLAS_GRASS_ALT
				elif _rng.randf() > 0.7:
					atlas = ATLAS_GRASS_ALT
				_island_layer.set_cell(Vector2i(x, y), SRC_GRASS, atlas)
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
		print("[农田] 此处不可耕种（请走到岛南侧田区）。")
		return

	if _crops.has(cell):
		var d: Dictionary = _crops[cell]
		var st: int = int(d["stage"])
		if st >= 3:
			_harvest_cell(cell, str(d["id"]))
		else:
			print("[农田] 作物生长中…")
		return

	if _farm_soil.get_cell_source_id(cell) != -1:
		_try_plant(cell)
		return

	_till_cell(cell)


func _till_cell(cell: Vector2i) -> void:
	_farm_soil.set_cell(cell, SRC_SOIL, SOIL_ATLAS)
	print("[农田] 已翻土 (%d,%d)" % [cell.x, cell.y])


func _try_plant(cell: Vector2i) -> void:
	var crop_id := ""
	var disp := ""
	if InventoryManager.count_item("corn_seed") > 0:
		crop_id = "corn"
		disp = "玉米"
	elif InventoryManager.count_item("tomato_seed") > 0:
		crop_id = "tomato"
		disp = "番茄"
	else:
		print("[农田] 没有种子（需要玉米种子或番茄种子）。")
		return
	var seed_key := crop_id + "_seed"
	if not InventoryManager.consume_item(seed_key, 1):
		return
	_crops[cell] = { "id": crop_id, "stage": 0, "grow": 0.0 }
	_refresh_crop_visual(cell)
	print("[农田] 已播种：%s" % disp)


func _harvest_cell(cell: Vector2i, crop_id: String) -> void:
	var name_key := "%d_%d" % [cell.x, cell.y]
	var spr: Node = _farm_crops.get_node_or_null(name_key)
	if spr:
		spr.queue_free()
	_crops.erase(cell)
	_farm_soil.erase_cell(cell)
	if crop_id == "corn":
		InventoryManager.add_item("corn", "玉米", 1 + (_rng.randi() % 2))
	elif crop_id == "tomato":
		InventoryManager.add_item("tomato", "番茄", 1 + (_rng.randi() % 2))
	print("[农田] 收获！")


func _refresh_crop_visual(cell: Vector2i) -> void:
	if not _crops.has(cell):
		return
	var d: Dictionary = _crops[cell]
	var crop_id: String = str(d["id"])
	var st: int = mini(int(d["stage"]), 3)
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
		if int(d["stage"]) >= 3:
			continue
		d["grow"] = float(d["grow"]) + delta
		while float(d["grow"]) >= GROW_SEC_STAGE and int(d["stage"]) < 3:
			d["grow"] = float(d["grow"]) - GROW_SEC_STAGE
			d["stage"] = int(d["stage"]) + 1
			_refresh_crop_visual(cell)
