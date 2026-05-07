const ItemDefs = {
  corn_seed:   { id: 'corn_seed',   name: '玉米种子',   emoji: '🌱', cropId: 'corn',    type: 'seed' },
  tomato_seed: { id: 'tomato_seed', name: '番茄种子',   emoji: '🌱', cropId: 'tomato',  type: 'seed' },
  carrot_seed: { id: 'carrot_seed', name: '胡萝卜种子', emoji: '🌱', cropId: 'carrot',  type: 'seed' },
  pumpkin_seed:{ id: 'pumpkin_seed',name: '南瓜种子',   emoji: '🌱', cropId: 'pumpkin', type: 'seed' },
  corn:        { id: 'corn',        name: '玉米',       emoji: '🌽', type: 'crop', sellPrice: 15 },
  tomato:      { id: 'tomato',      name: '番茄',       emoji: '🍅', type: 'crop', sellPrice: 20 },
  carrot:      { id: 'carrot',      name: '胡萝卜',     emoji: '🥕', type: 'crop', sellPrice: 12 },
  pumpkin:     { id: 'pumpkin',     name: '南瓜',       emoji: '🎃', type: 'crop', sellPrice: 50 },
  wood:        { id: 'wood',        name: '木材',       emoji: '🪵', type: 'material', sellPrice: 5 },
  apple:       { id: 'apple',       name: '苹果',       emoji: '🍎', type: 'food', sellPrice: 8 },
};

class Inventory {
  constructor(size) {
    this.size = size || CONST.INV_SLOTS;
    this.slots = new Array(this.size).fill(null);
  }

  addItem(itemId, count) {
    count = count || 1;
    let remaining = count;

    for (let i = 0; i < this.size && remaining > 0; i++) {
      const slot = this.slots[i];
      if (slot && slot.id === itemId && slot.count < CONST.MAX_STACK) {
        const canAdd = Math.min(remaining, CONST.MAX_STACK - slot.count);
        slot.count += canAdd;
        remaining -= canAdd;
      }
    }

    for (let i = 0; i < this.size && remaining > 0; i++) {
      if (!this.slots[i]) {
        const toAdd = Math.min(remaining, CONST.MAX_STACK);
        this.slots[i] = { id: itemId, count: toAdd };
        remaining -= toAdd;
      }
    }

    return count - remaining;
  }

  removeItem(itemId, count) {
    count = count || 1;
    let remaining = count;

    for (let i = this.size - 1; i >= 0 && remaining > 0; i--) {
      const slot = this.slots[i];
      if (slot && slot.id === itemId) {
        const canRemove = Math.min(remaining, slot.count);
        slot.count -= canRemove;
        remaining -= canRemove;
        if (slot.count <= 0) this.slots[i] = null;
      }
    }

    return count - remaining;
  }

  hasItem(itemId, count) {
    count = count || 1;
    let total = 0;
    for (const slot of this.slots) {
      if (slot && slot.id === itemId) total += slot.count;
    }
    return total >= count;
  }

  countItem(itemId) {
    let total = 0;
    for (const slot of this.slots) {
      if (slot && slot.id === itemId) total += slot.count;
    }
    return total;
  }

  getSeeds() {
    const seeds = new Set();
    for (const slot of this.slots) {
      if (slot) {
        const def = ItemDefs[slot.id];
        if (def && def.type === 'seed') seeds.add(slot.id);
      }
    }
    return [...seeds];
  }

  getSellableItems() {
    const items = new Map();
    for (const slot of this.slots) {
      if (slot) {
        const def = ItemDefs[slot.id];
        if (def && def.sellPrice) {
          const current = items.get(slot.id) || 0;
          items.set(slot.id, current + slot.count);
        }
      }
    }
    return items;
  }
}
