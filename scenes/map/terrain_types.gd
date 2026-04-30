class_name TerrainTypes
extends RefCounted

enum Type {
	GRASS,
	GRASS_CORNER_TL,
	GRASS_CORNER_TR,
	GRASS_CORNER_BL,
	GRASS_CORNER_BR,
	GRASS_EDGE_T,
	GRASS_EDGE_B,
	GRASS_EDGE_L,
	GRASS_EDGE_R,
}

static func get_name(type: int) -> String:
	match type:
		Type.GRASS:
			return "草地"
		Type.GRASS_CORNER_TL:
			return "草地-左上角"
		Type.GRASS_CORNER_TR:
			return "草地-右上角"
		Type.GRASS_CORNER_BL:
			return "草地-左下角"
		Type.GRASS_CORNER_BR:
			return "草地-右下角"
		Type.GRASS_EDGE_T:
			return "草地-上边"
		Type.GRASS_EDGE_B:
			return "草地-下边"
		Type.GRASS_EDGE_L:
			return "草地-左边"
		Type.GRASS_EDGE_R:
			return "草地-右边"
		_:
			return "未知"
