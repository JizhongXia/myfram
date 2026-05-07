const CropDefs = {
  corn: {
    id: 'corn',
    name: '玉米',
    seedName: '玉米种子',
    emoji: '🌽',
    seedEmoji: '🌱',
    growthStages: 4,
    growthDays: [1, 2, 2, 1],
    needsWater: true,
    harvestYield: { id: 'corn', count: 2 },
    stageEmoji: ['·', '🌱', '🌿', '🌾', '🌽'],
  },
  tomato: {
    id: 'tomato',
    name: '番茄',
    seedName: '番茄种子',
    emoji: '🍅',
    seedEmoji: '🌱',
    growthStages: 4,
    growthDays: [1, 1, 2, 1],
    needsWater: true,
    harvestYield: { id: 'tomato', count: 3 },
    stageEmoji: ['·', '🌱', '🌿', '🌻', '🍅'],
  },
  carrot: {
    id: 'carrot',
    name: '胡萝卜',
    seedName: '胡萝卜种子',
    emoji: '🥕',
    seedEmoji: '🌱',
    growthStages: 3,
    growthDays: [1, 2, 1],
    needsWater: true,
    harvestYield: { id: 'carrot', count: 2 },
    stageEmoji: ['·', '🌱', '🌿', '🥕'],
  },
  pumpkin: {
    id: 'pumpkin',
    name: '南瓜',
    seedName: '南瓜种子',
    emoji: '🎃',
    seedEmoji: '🌱',
    growthStages: 5,
    growthDays: [1, 2, 2, 2, 1],
    needsWater: true,
    harvestYield: { id: 'pumpkin', count: 1 },
    stageEmoji: ['·', '🌱', '🌿', '🌻', '🍈', '🎃'],
  },
};

const FarmTileState = {
  NONE: 'none',
  TILLED: 'tilled',
  PLANTED: 'planted',
};

class FarmTile {
  constructor() {
    this.state = FarmTileState.NONE;
    this.cropId = null;
    this.stage = 0;
    this.daysInStage = 0;
    this.watered = false;
  }

  till() {
    if (this.state !== FarmTileState.NONE) return false;
    this.state = FarmTileState.TILLED;
    return true;
  }

  plant(cropId) {
    if (this.state !== FarmTileState.TILLED) return false;
    this.state = FarmTileState.PLANTED;
    this.cropId = cropId;
    this.stage = 0;
    this.daysInStage = 0;
    this.watered = false;
    return true;
  }

  water() {
    if (this.state !== FarmTileState.PLANTED) return false;
    if (this.watered) return false;
    this.watered = true;
    return true;
  }

  advanceDay() {
    if (this.state !== FarmTileState.PLANTED || !this.cropId) return;
    const def = CropDefs[this.cropId];
    if (!def) return;
    if (this.stage >= def.growthStages) return;

    if (this.watered) {
      this.daysInStage++;
      const needed = def.growthDays[this.stage] || 1;
      if (this.daysInStage >= needed) {
        this.stage++;
        this.daysInStage = 0;
      }
    }
    this.watered = false;
  }

  isMature() {
    if (!this.cropId) return false;
    const def = CropDefs[this.cropId];
    return def && this.stage >= def.growthStages;
  }

  harvest() {
    if (!this.isMature()) return null;
    const def = CropDefs[this.cropId];
    const yield_ = { ...def.harvestYield };
    this.state = FarmTileState.NONE;
    this.cropId = null;
    this.stage = 0;
    this.daysInStage = 0;
    this.watered = false;
    return yield_;
  }

  getEmoji() {
    if (this.state === FarmTileState.TILLED) return '▪';
    if (this.state === FarmTileState.PLANTED && this.cropId) {
      const def = CropDefs[this.cropId];
      if (def) return def.stageEmoji[this.stage] || '?';
    }
    return null;
  }

  getDescription() {
    if (this.state === FarmTileState.NONE) return '空地';
    if (this.state === FarmTileState.TILLED) return '已翻土（可播种）';
    if (this.state === FarmTileState.PLANTED && this.cropId) {
      const def = CropDefs[this.cropId];
      if (!def) return '未知作物';
      if (this.isMature()) return `${def.name} 已成熟！可收获`;
      const waterStr = this.watered ? '✅已浇水' : '❌未浇水';
      return `${def.name} 阶段${this.stage}/${def.growthStages} ${waterStr}`;
    }
    return '?';
  }
}
