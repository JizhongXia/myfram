extends Node2D

const CELL_SIZE: int = 16

var map_data: MapData

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

func _ready() -> void:
	map_data = MapData.new()
	map_data.debug_print_terrain()
	_render_map()
	print("MapManager ready. Click on the map to inspect tiles.")

func _render_map() -> void:
	if tile_map_layer == null or tile_map_layer.tile_set == null:
		_render_fallback()
		return
	for y in range(MapData.TOTAL_SIZE):
		for x in range(MapData.TOTAL_SIZE):
			var terrain := map_data.get_terrain(x, y)
			tile_map_layer.set_cell(Vector2i(x, y), 0, _get_atlas_coords(terrain))

func _get_atlas_coords(terrain: int) -> Vector2i:
	match terrain:
		TerrainTypes.Type.GRASS:
			return Vector2i(0, 0)
		TerrainTypes.Type.GRASS_CORNER_TL:
			return Vector2i(1, 0)
		TerrainTypes.Type.GRASS_CORNER_TR:
			return Vector2i(2, 0)
		TerrainTypes.Type.GRASS_CORNER_BL:
			return Vector2i(1, 1)
		TerrainTypes.Type.GRASS_CORNER_BR:
			return Vector2i(2, 1)
		TerrainTypes.Type.GRASS_EDGE_T:
			return Vector2i(3, 0)
		TerrainTypes.Type.GRASS_EDGE_B:
			return Vector2i(3, 1)
		TerrainTypes.Type.GRASS_EDGE_L:
			return Vector2i(4, 0)
		TerrainTypes.Type.GRASS_EDGE_R:
			return Vector2i(4, 1)
		_:
			return Vector2i(0, 0)

func _render_fallback() -> void:
	for y in range(MapData.TOTAL_SIZE):
		for x in range(MapData.TOTAL_SIZE):
			var terrain := map_data.get_terrain(x, y)
			var rect := ColorRect.new()
			rect.size = Vector2(CELL_SIZE, CELL_SIZE)
			rect.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			rect.color = _get_terrain_color(terrain)
			add_child(rect)

func _get_terrain_color(terrain: int) -> Color:
	match terrain:
		TerrainTypes.Type.GRASS:
			return Color(0.3, 0.7, 0.3)
		TerrainTypes.Type.GRASS_CORNER_TL, TerrainTypes.Type.GRASS_CORNER_TR, \
		TerrainTypes.Type.GRASS_CORNER_BL, TerrainTypes.Type.GRASS_CORNER_BR:
			return Color(0.2, 0.5, 0.2)
		TerrainTypes.Type.GRASS_EDGE_T, TerrainTypes.Type.GRASS_EDGE_B, \
		TerrainTypes.Type.GRASS_EDGE_L, TerrainTypes.Type.GRASS_EDGE_R:
			return Color(0.25, 0.6, 0.25)
		_:
			return Color(0.5, 0.5, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := get_cell_under_mouse()
		if cell.x >= 0 and cell.x < MapData.TOTAL_SIZE and cell.y >= 0 and cell.y < MapData.TOTAL_SIZE:
			var terrain: int = map_data.get_terrain(cell.x, cell.y)
			var terrain_name: String = TerrainTypes.get_name(terrain)
			var area := "农场区域" if map_data.is_in_farm_area(cell.x, cell.y) else "边界区域"
			print("Clicked: (%d, %d) - %s [%s]" % [cell.x, cell.y, terrain_name, area])

func get_cell_under_mouse() -> Vector2i:
	var mouse_pos := get_global_mouse_position()
	return Vector2i(int(mouse_pos.x / CELL_SIZE), int(mouse_pos.y / CELL_SIZE))
