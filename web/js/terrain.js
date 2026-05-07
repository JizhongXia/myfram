const TerrainType = {
  GRASS: 0,
  GRASS_CORNER_TL: 1,
  GRASS_CORNER_TR: 2,
  GRASS_CORNER_BL: 3,
  GRASS_CORNER_BR: 4,
  GRASS_EDGE_T: 5,
  GRASS_EDGE_B: 6,
  GRASS_EDGE_L: 7,
  GRASS_EDGE_R: 8,
  WATER: 9,
  TREE: 10,
};

const TerrainNames = {
  [TerrainType.GRASS]: '草地',
  [TerrainType.GRASS_CORNER_TL]: '草地-左上角',
  [TerrainType.GRASS_CORNER_TR]: '草地-右上角',
  [TerrainType.GRASS_CORNER_BL]: '草地-左下角',
  [TerrainType.GRASS_CORNER_BR]: '草地-右下角',
  [TerrainType.GRASS_EDGE_T]: '草地-上边',
  [TerrainType.GRASS_EDGE_B]: '草地-下边',
  [TerrainType.GRASS_EDGE_L]: '草地-左边',
  [TerrainType.GRASS_EDGE_R]: '草地-右边',
  [TerrainType.WATER]: '水',
  [TerrainType.TREE]: '树木',
};

const TerrainEmoji = {
  [TerrainType.GRASS]: '🟩',
  [TerrainType.GRASS_CORNER_TL]: '↖️',
  [TerrainType.GRASS_CORNER_TR]: '↗️',
  [TerrainType.GRASS_CORNER_BL]: '↙️',
  [TerrainType.GRASS_CORNER_BR]: '↘️',
  [TerrainType.GRASS_EDGE_T]: '⬆️',
  [TerrainType.GRASS_EDGE_B]: '⬇️',
  [TerrainType.GRASS_EDGE_L]: '⬅️',
  [TerrainType.GRASS_EDGE_R]: '➡️',
  [TerrainType.WATER]: '🌊',
  [TerrainType.TREE]: '🌳',
};

const TerrainColors = {
  [TerrainType.GRASS]:           '#4a8c3f',
  [TerrainType.GRASS_CORNER_TL]: '#3a7030',
  [TerrainType.GRASS_CORNER_TR]: '#3a7030',
  [TerrainType.GRASS_CORNER_BL]: '#3a7030',
  [TerrainType.GRASS_CORNER_BR]: '#3a7030',
  [TerrainType.GRASS_EDGE_T]:    '#408035',
  [TerrainType.GRASS_EDGE_B]:    '#408035',
  [TerrainType.GRASS_EDGE_L]:    '#408035',
  [TerrainType.GRASS_EDGE_R]:    '#408035',
  [TerrainType.WATER]:           '#2980b9',
  [TerrainType.TREE]:            '#2d6b22',
};
