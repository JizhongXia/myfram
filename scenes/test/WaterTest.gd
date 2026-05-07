extends Node2D
## 海水贴图测试：整层 TileMapLayer 铺满 4 帧水动画（与主地图同源素材）

const TILE_SIZE := 64
## 视口能铺满的格数（可改大做压力测试）
const MAP_W := 24
const MAP_H := 14

const SRC_WATER := 0

@onready var _layer: TileMapLayer = $Water

var _tile_set: TileSet
var _water_frame: int = 0
var _water_tick: float = 0.0
const WATER_ANIM_SEC := 0.18


func _ready() -> void:
	_tile_set = _build_water_tileset()
	_layer.tile_set = _tile_set
	_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_paint_all_water()
	print("WaterTest: %d×%d 格已铺满海水；关闭场景或改 main_scene 回到主场景。" % [MAP_W, MAP_H])


func _build_water_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var strip := Image.create(TILE_SIZE * 4, TILE_SIZE, false, Image.FORMAT_RGBA8)
	for i in 4:
		var path := "res://assets/sprout-lands/graphics/water/%d.png" % i
		var frame := Image.new()
		if frame.load(path) != OK:
			push_error("WaterTest: missing %s" % path)
			continue
		strip.blit_rect(frame, Rect2i(0, 0, TILE_SIZE, TILE_SIZE), Vector2i(i * TILE_SIZE, 0))
	var water_tex := ImageTexture.create_from_image(strip)
	var water_src := TileSetAtlasSource.new()
	water_src.texture = water_tex
	water_src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	ts.add_source(water_src, SRC_WATER)
	return ts


func _paint_all_water() -> void:
	for y in MAP_H:
		for x in MAP_W:
			_layer.set_cell(Vector2i(x, y), SRC_WATER, Vector2i(_water_frame, 0))


func _process(delta: float) -> void:
	_water_tick += delta
	if _water_tick < WATER_ANIM_SEC:
		return
	_water_tick = 0.0
	_water_frame = (_water_frame + 1) % 4
	for y in MAP_H:
		for x in MAP_W:
			_layer.set_cell(Vector2i(x, y), SRC_WATER, Vector2i(_water_frame, 0))
