extends Node2D

## 世界：动态海水（water 0–3 图集帧）+ 瓦片草地小岛 + 原始丛林（Sprite2D 大树，避免与 64 草地网格混源尺寸问题）

const TILE_SIZE := 64
const MAP_W := 48
const MAP_H := 32

const ATLAS_GRASS_MAIN := Vector2i(4, 4)
const ATLAS_GRASS_ALT := Vector2i(5, 3)
const ATLAS_GRASS_JUNGLE := Vector2i(3, 4)

const SRC_WATER := 0
const SRC_GRASS := 1

@onready var _water_layer: TileMapLayer = $Water
@onready var _island_layer: TileMapLayer = $Island
@onready var _jungle_root: Node2D = $Jungle
@onready var _camera: Camera2D = $Camera2D

var _tile_set: TileSet
var _water_cells: Array[Vector2i] = []
var _water_frame: int = 0
var _water_tick: float = 0.0
const WATER_ANIM_SEC := 0.18

var _rng := RandomNumberGenerator.new()

var _tex_tree_big: ImageTexture
var _tex_tree_small: ImageTexture


func _ready() -> void:
	_rng.randomize()
	_tex_tree_big = _load_image_texture("res://assets/sprout-lands/graphics/objects/tree_medium.png")
	_tex_tree_small = _load_image_texture("res://assets/sprout-lands/graphics/objects/tree_small.png")

	_tile_set = _build_tileset()
	_water_layer.tile_set = _tile_set
	_island_layer.tile_set = _tile_set

	_paint_world()

	_jungle_root.y_sort_enabled = true

	_camera.position = Vector2(MAP_W * TILE_SIZE * 0.5, MAP_H * TILE_SIZE * 0.5)
	_camera.zoom = Vector2(0.45, 0.45)
	_camera.enabled = true

	print("Island map: %dx%d, animated water 0–3, jungle sprites." % [MAP_W, MAP_H])


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

	return ts


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


func _paint_world() -> void:
	_water_cells.clear()
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
			else:
				_water_cells.append(Vector2i(x, y))
				_water_layer.set_cell(Vector2i(x, y), SRC_WATER, Vector2i(_water_frame, 0))
	_apply_water_frame()


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
	_jungle_root.add_child(spr)


func _apply_water_frame() -> void:
	for c: Vector2i in _water_cells:
		_water_layer.set_cell(c, SRC_WATER, Vector2i(_water_frame, 0))


func _process(delta: float) -> void:
	_water_tick += delta
	if _water_tick >= WATER_ANIM_SEC:
		_water_tick = 0.0
		_water_frame = (_water_frame + 1) % 4
		_apply_water_frame()
