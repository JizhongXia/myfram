class Game {
  constructor() {
    this.mapData = new MapData();
    this.inventory = new Inventory();
    this.currentTool = 'hand';
    this.selectedSeed = null;
    this.day = 1;
    this.season = 0;
    this.gold = 100;
    this.logs = [];

    this._initInventory();
  }

  _initInventory() {
    this.inventory.addItem('corn_seed', 10);
    this.inventory.addItem('tomato_seed', 8);
    this.inventory.addItem('carrot_seed', 6);
    this.inventory.addItem('pumpkin_seed', 3);
    this.inventory.addItem('apple', 5);
    this.inventory.addItem('wood', 10);
  }

  setTool(tool) {
    this.currentTool = tool;
  }

  setSeed(seedId) {
    this.selectedSeed = seedId;
  }

  getSeasonName() {
    return CONST.SEASONS[this.season];
  }

  log(msg, type) {
    type = type || 'info';
    this.logs.unshift({ msg, type, day: this.day });
    if (this.logs.length > 50) this.logs.pop();
  }

  handleClick(x, y) {
    if (x < 0 || x >= CONST.TOTAL_SIZE || y < 0 || y >= CONST.TOTAL_SIZE) return null;

    const terrain = this.mapData.getTerrain(x, y);
    const tool = this.currentTool;

    if (tool === 'hand') {
      return this._inspect(x, y);
    }

    if (!this.mapData.isInFarmArea(x, y)) {
      if (tool === 'axe' && terrain === TerrainType.TREE) {
        return this._chopTree(x, y);
      }
      this.log(`(${x},${y}) 不在农场区域，无法操作`, 'error');
      return { action: 'error', msg: '不在农场区域' };
    }

    switch (tool) {
      case 'hoe':    return this._hoe(x, y);
      case 'water':  return this._water(x, y);
      case 'seed':   return this._plant(x, y);
      case 'harvest': return this._harvest(x, y);
      case 'axe':
        if (terrain === TerrainType.TREE) return this._chopTree(x, y);
        this.log(`(${x},${y}) 这里没有树`, 'error');
        return { action: 'error', msg: '这里没有树' };
      default:
        return this._inspect(x, y);
    }
  }

  _inspect(x, y) {
    const terrain = this.mapData.getTerrain(x, y);
    const farm = this.mapData.getFarmState(x, y);
    const tName = TerrainNames[terrain] || '未知';
    const area = this.mapData.isInFarmArea(x, y) ? '农场区域' : '边界区域';
    let farmDesc = '';
    if (farm) {
      farmDesc = '\n农田: ' + farm.getDescription();
    }
    const msg = `(${x},${y}) ${tName} [${area}]${farmDesc}`;
    this.log(msg, 'info');
    return { action: 'inspect', x, y, terrain, tName, area, farm, msg };
  }

  _hoe(x, y) {
    const terrain = this.mapData.getTerrain(x, y);
    if (terrain === TerrainType.TREE) {
      this.log(`(${x},${y}) 先砍掉树再翻土`, 'error');
      return { action: 'error', msg: '先砍掉树' };
    }

    let farm = this.mapData.getFarmState(x, y);
    if (!farm) {
      farm = new FarmTile();
      this.mapData.setFarmState(x, y, farm);
    }

    if (farm.till()) {
      this.log(`⛏️ (${x},${y}) 翻土成功`, 'action');
      return { action: 'hoe', success: true };
    }
    this.log(`(${x},${y}) 无法翻土 - ${farm.getDescription()}`, 'error');
    return { action: 'error', msg: '无法翻土' };
  }

  _water(x, y) {
    const farm = this.mapData.getFarmState(x, y);
    if (!farm || farm.state !== FarmTileState.PLANTED) {
      this.log(`(${x},${y}) 没有作物可浇水`, 'error');
      return { action: 'error', msg: '没有作物可浇水' };
    }
    if (farm.water()) {
      const def = CropDefs[farm.cropId];
      this.log(`💧 (${x},${y}) 给${def ? def.name : '作物'}浇水`, 'action');
      return { action: 'water', success: true };
    }
    this.log(`(${x},${y}) 今天已经浇过水了`, 'error');
    return { action: 'error', msg: '今天已浇水' };
  }

  _plant(x, y) {
    const farm = this.mapData.getFarmState(x, y);
    if (!farm || farm.state !== FarmTileState.TILLED) {
      this.log(`(${x},${y}) 需要先翻土`, 'error');
      return { action: 'error', msg: '需要先翻土' };
    }

    if (!this.selectedSeed) {
      this.log('请先在右侧面板选择种子类型', 'error');
      return { action: 'need_seed' };
    }

    if (!this.inventory.hasItem(this.selectedSeed, 1)) {
      const def = ItemDefs[this.selectedSeed];
      this.log(`没有足够的${def ? def.name : '种子'}`, 'error');
      return { action: 'error', msg: '种子不足' };
    }

    const itemDef = ItemDefs[this.selectedSeed];
    if (!itemDef || !itemDef.cropId) {
      this.log('无效的种子类型', 'error');
      return { action: 'error', msg: '无效种子' };
    }

    if (farm.plant(itemDef.cropId)) {
      this.inventory.removeItem(this.selectedSeed, 1);
      const cropDef = CropDefs[itemDef.cropId];
      this.log(`🌱 (${x},${y}) 种下了${cropDef ? cropDef.name : '作物'}`, 'plant');
      return { action: 'plant', success: true, cropId: itemDef.cropId };
    }

    this.log(`(${x},${y}) 无法播种`, 'error');
    return { action: 'error', msg: '无法播种' };
  }

  _harvest(x, y) {
    const farm = this.mapData.getFarmState(x, y);
    if (!farm || !farm.isMature()) {
      this.log(`(${x},${y}) 没有成熟的作物可收获`, 'error');
      return { action: 'error', msg: '没有成熟作物' };
    }

    const yield_ = farm.harvest();
    if (yield_) {
      const added = this.inventory.addItem(yield_.id, yield_.count);
      const def = ItemDefs[yield_.id];
      this.log(`🧺 (${x},${y}) 收获了 ${def ? def.name : yield_.id} ×${added}`, 'harvest');
      return { action: 'harvest', success: true, item: yield_ };
    }

    this.log(`(${x},${y}) 收获失败`, 'error');
    return { action: 'error', msg: '收获失败' };
  }

  _chopTree(x, y) {
    this.mapData.setTerrain(x, y, TerrainType.GRASS);
    const woodCount = 1 + Math.floor(Math.random() * 3);
    const added = this.inventory.addItem('wood', woodCount);
    if (Math.random() < 0.3) {
      this.inventory.addItem('apple', 1);
      this.log(`🪓 (${x},${y}) 砍倒了树！获得 🪵×${added} 🍎×1`, 'harvest');
    } else {
      this.log(`🪓 (${x},${y}) 砍倒了树！获得 🪵×${added}`, 'action');
    }
    return { action: 'chop', success: true };
  }

  advanceDay() {
    for (let y = 0; y < CONST.TOTAL_SIZE; y++) {
      for (let x = 0; x < CONST.TOTAL_SIZE; x++) {
        const farm = this.mapData.getFarmState(x, y);
        if (farm) farm.advanceDay();
      }
    }

    this.day++;
    if (this.day > CONST.DAYS_PER_SEASON * 4) {
      this.day = 1;
    }
    this.season = Math.floor((this.day - 1) / CONST.DAYS_PER_SEASON) % 4;

    this.log(`☀️ 新的一天！第 ${this.day} 天 · ${this.getSeasonName()}`, 'action');
    return { day: this.day, season: this.getSeasonName() };
  }

  sellItem(itemId, count) {
    const def = ItemDefs[itemId];
    if (!def || !def.sellPrice) return { success: false, msg: '此物品不可出售' };

    count = count || 1;
    const available = this.inventory.countItem(itemId);
    const toSell = Math.min(count, available);
    if (toSell <= 0) return { success: false, msg: '没有该物品' };

    const removed = this.inventory.removeItem(itemId, toSell);
    const earned = removed * def.sellPrice;
    this.gold += earned;
    this.log(`💰 出售 ${def.name}×${removed}，获得 ${earned} 金币`, 'harvest');
    return { success: true, earned, removed };
  }
}
