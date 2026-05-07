class MapData {
  constructor() {
    this.terrain = [];
    this.farmState = [];
    this._init();
  }

  _init() {
    const S = CONST.TOTAL_SIZE;
    for (let y = 0; y < S; y++) {
      this.terrain[y] = [];
      this.farmState[y] = [];
      for (let x = 0; x < S; x++) {
        this.terrain[y][x] = this._calcTerrain(x, y);
        this.farmState[y][x] = null;
      }
    }
    this._placeRandomTrees();
  }

  _calcTerrain(x, y) {
    const S = CONST.TOTAL_SIZE;
    const B = CONST.BORDER_SIZE;
    const inLeft = x < B, inRight = x >= S - B;
    const inTop = y < B, inBottom = y >= S - B;
    const isCorner = (inLeft || inRight) && (inTop || inBottom);
    const isEdge = !isCorner && (inLeft || inRight || inTop || inBottom);

    if (isCorner) {
      if (inLeft && inTop) return TerrainType.GRASS_CORNER_TL;
      if (inRight && inTop) return TerrainType.GRASS_CORNER_TR;
      if (inLeft && inBottom) return TerrainType.GRASS_CORNER_BL;
      return TerrainType.GRASS_CORNER_BR;
    }
    if (isEdge) {
      if (inTop) return TerrainType.GRASS_EDGE_T;
      if (inBottom) return TerrainType.GRASS_EDGE_B;
      if (inLeft) return TerrainType.GRASS_EDGE_L;
      return TerrainType.GRASS_EDGE_R;
    }
    return TerrainType.GRASS;
  }

  _placeRandomTrees() {
    const rng = (n) => Math.floor(Math.random() * n);
    for (let i = 0; i < 40; i++) {
      const x = CONST.FARM_START + rng(CONST.FARM_SIZE);
      const y = CONST.FARM_START + rng(CONST.FARM_SIZE);
      if (this.terrain[y][x] === TerrainType.GRASS && rng(3) === 0) {
        this.terrain[y][x] = TerrainType.TREE;
      }
    }
  }

  getTerrain(x, y) {
    if (x < 0 || x >= CONST.TOTAL_SIZE || y < 0 || y >= CONST.TOTAL_SIZE) return -1;
    return this.terrain[y][x];
  }

  setTerrain(x, y, t) {
    if (x < 0 || x >= CONST.TOTAL_SIZE || y < 0 || y >= CONST.TOTAL_SIZE) return;
    this.terrain[y][x] = t;
  }

  getFarmState(x, y) {
    if (x < 0 || x >= CONST.TOTAL_SIZE || y < 0 || y >= CONST.TOTAL_SIZE) return null;
    return this.farmState[y][x];
  }

  setFarmState(x, y, state) {
    if (x < 0 || x >= CONST.TOTAL_SIZE || y < 0 || y >= CONST.TOTAL_SIZE) return;
    this.farmState[y][x] = state;
  }

  isInFarmArea(x, y) {
    return x >= CONST.FARM_START && x < CONST.FARM_END
        && y >= CONST.FARM_START && y < CONST.FARM_END;
  }

  isInBorderArea(x, y) {
    return !this.isInFarmArea(x, y)
        && x >= 0 && x < CONST.TOTAL_SIZE
        && y >= 0 && y < CONST.TOTAL_SIZE;
  }
}
