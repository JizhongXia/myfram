class_name MapData
extends RefCounted

const TerrainTypes = preload("res://scenes/map/terrain_types.gd")

const TOTAL_SIZE: int = 60
const FARM_SIZE: int = 50
const BORDER_SIZE: int = 5

var _terrain: Array = []

func _init() -> void:
	_terrain.resize(TOTAL_SIZE)
	for y in range(TOTAL_SIZE):
		_terrain[y] = []
		_terrain[y].resize(TOTAL_SIZE)
		for x in range(TOTAL_SIZE):
			_terrain[y][x] = _calculate_terrain(x, y)

func _calculate_terrain(x: int, y: int) -> int:
	if is_corner(x, y):
		if x < BORDER_SIZE and y < BORDER_SIZE:
			return TerrainTypes.Type.GRASS_CORNER_TL
		elif x >= TOTAL_SIZE - BORDER_SIZE and y < BORDER_SIZE:
			return TerrainTypes.Type.GRASS_CORNER_TR
		elif x < BORDER_SIZE and y >= TOTAL_SIZE - BORDER_SIZE:
			return TerrainTypes.Type.GRASS_CORNER_BL
		else:
			return TerrainTypes.Type.GRASS_CORNER_BR
	elif is_edge(x, y):
		if y < BORDER_SIZE:
			return TerrainTypes.Type.GRASS_EDGE_T
		elif y >= TOTAL_SIZE - BORDER_SIZE:
			return TerrainTypes.Type.GRASS_EDGE_B
		elif x < BORDER_SIZE:
			return TerrainTypes.Type.GRASS_EDGE_L
		else:
			return TerrainTypes.Type.GRASS_EDGE_R
	else:
		return TerrainTypes.Type.GRASS

func get_terrain(x: int, y: int) -> int:
	if x < 0 or x >= TOTAL_SIZE or y < 0 or y >= TOTAL_SIZE:
		return -1
	return _terrain[y][x]

func set_terrain(x: int, y: int, terrain_type: int) -> void:
	if x < 0 or x >= TOTAL_SIZE or y < 0 or y >= TOTAL_SIZE:
		return
	_terrain[y][x] = terrain_type

func is_in_farm_area(x: int, y: int) -> bool:
	return x >= BORDER_SIZE and x < BORDER_SIZE + FARM_SIZE and y >= BORDER_SIZE and y < BORDER_SIZE + FARM_SIZE

func is_in_border_area(x: int, y: int) -> bool:
	return not is_in_farm_area(x, y) and x >= 0 and x < TOTAL_SIZE and y >= 0 and y < TOTAL_SIZE

func is_corner(x: int, y: int) -> bool:
	var in_left := x < BORDER_SIZE
	var in_right := x >= TOTAL_SIZE - BORDER_SIZE
	var in_top := y < BORDER_SIZE
	var in_bottom := y >= TOTAL_SIZE - BORDER_SIZE
	return (in_left or in_right) and (in_top or in_bottom)

func is_edge(x: int, y: int) -> bool:
	if is_corner(x, y):
		return false
	return x < BORDER_SIZE or x >= TOTAL_SIZE - BORDER_SIZE or y < BORDER_SIZE or y >= TOTAL_SIZE - BORDER_SIZE

func debug_print_terrain() -> void:
	print("=== Map Info ===")
	print("Total size: %d x %d" % [TOTAL_SIZE, TOTAL_SIZE])
	print("Farm area: %d x %d (offset: %d)" % [FARM_SIZE, FARM_SIZE, BORDER_SIZE])
	print("")
	print("=== Terrain Grid (simplified) ===")
	for y in range(TOTAL_SIZE):
		var row := ""
		for x in range(TOTAL_SIZE):
			var t := get_terrain(x, y)
			match t:
				TerrainTypes.Type.GRASS:
					row += "."
				TerrainTypes.Type.GRASS_CORNER_TL, TerrainTypes.Type.GRASS_CORNER_TR, \
				TerrainTypes.Type.GRASS_CORNER_BL, TerrainTypes.Type.GRASS_CORNER_BR:
					row += "+"
				TerrainTypes.Type.GRASS_EDGE_T, TerrainTypes.Type.GRASS_EDGE_B:
					row += "-"
				TerrainTypes.Type.GRASS_EDGE_L, TerrainTypes.Type.GRASS_EDGE_R:
					row += "|"
				_:
					row += "?"
		print(row)
