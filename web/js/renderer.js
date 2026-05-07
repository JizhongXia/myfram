class Renderer {
  constructor(canvas, mapData) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.mapData = mapData;
    this.cellSize = CONST.CELL_PX;
    this.offsetX = 0;
    this.offsetY = 0;
    this.hoveredCell = null;
    this.selectedCell = null;
    this._resize();
  }

  _resize() {
    const container = this.canvas.parentElement;
    this.canvas.width = container.clientWidth;
    this.canvas.height = container.clientHeight;
  }

  setView(ox, oy) {
    this.offsetX = ox;
    this.offsetY = oy;
  }

  screenToCell(sx, sy) {
    const cx = Math.floor((sx - this.offsetX) / this.cellSize);
    const cy = Math.floor((sy - this.offsetY) / this.cellSize);
    return { x: cx, y: cy };
  }

  cellToScreen(cx, cy) {
    return {
      x: cx * this.cellSize + this.offsetX,
      y: cy * this.cellSize + this.offsetY,
    };
  }

  render() {
    const ctx = this.ctx;
    const w = this.canvas.width;
    const h = this.canvas.height;
    const cs = this.cellSize;

    ctx.fillStyle = '#0a1628';
    ctx.fillRect(0, 0, w, h);

    const startX = Math.max(0, Math.floor(-this.offsetX / cs));
    const startY = Math.max(0, Math.floor(-this.offsetY / cs));
    const endX = Math.min(CONST.TOTAL_SIZE, Math.ceil((w - this.offsetX) / cs));
    const endY = Math.min(CONST.TOTAL_SIZE, Math.ceil((h - this.offsetY) / cs));

    for (let y = startY; y < endY; y++) {
      for (let x = startX; x < endX; x++) {
        const terrain = this.mapData.getTerrain(x, y);
        const sx = x * cs + this.offsetX;
        const sy = y * cs + this.offsetY;

        ctx.fillStyle = TerrainColors[terrain] || '#333';
        ctx.fillRect(sx, sy, cs, cs);

        ctx.strokeStyle = 'rgba(0,0,0,0.15)';
        ctx.strokeRect(sx, sy, cs, cs);

        const farm = this.mapData.getFarmState(x, y);
        if (farm) {
          this._renderFarmTile(ctx, farm, sx, sy, cs);
        } else if (terrain === TerrainType.TREE) {
          this._renderEmoji(ctx, '🌳', sx, sy, cs);
        }
      }
    }

    if (this.hoveredCell) {
      const hx = this.hoveredCell.x * cs + this.offsetX;
      const hy = this.hoveredCell.y * cs + this.offsetY;
      ctx.strokeStyle = 'rgba(255,255,255,0.6)';
      ctx.lineWidth = 2;
      ctx.strokeRect(hx + 1, hy + 1, cs - 2, cs - 2);
      ctx.lineWidth = 1;
    }

    if (this.selectedCell) {
      const sx2 = this.selectedCell.x * cs + this.offsetX;
      const sy2 = this.selectedCell.y * cs + this.offsetY;
      ctx.strokeStyle = '#e2b714';
      ctx.lineWidth = 2;
      ctx.strokeRect(sx2, sy2, cs, cs);
      ctx.lineWidth = 1;
    }

    this._renderMinimap(ctx, w, h);
  }

  _renderFarmTile(ctx, farm, sx, sy, cs) {
    if (farm.state === FarmTileState.TILLED) {
      ctx.fillStyle = '#8B6914';
      ctx.fillRect(sx + 1, sy + 1, cs - 2, cs - 2);
      if (farm.watered) {
        ctx.fillStyle = '#6B4914';
        ctx.fillRect(sx + 1, sy + 1, cs - 2, cs - 2);
      }
    } else if (farm.state === FarmTileState.PLANTED) {
      ctx.fillStyle = farm.watered ? '#6B4914' : '#8B6914';
      ctx.fillRect(sx + 1, sy + 1, cs - 2, cs - 2);
      const emoji = farm.getEmoji();
      if (emoji) {
        this._renderEmoji(ctx, emoji, sx, sy, cs);
      }
      if (farm.isMature()) {
        ctx.strokeStyle = '#ffd700';
        ctx.lineWidth = 1;
        ctx.strokeRect(sx + 2, sy + 2, cs - 4, cs - 4);
      }
    }
  }

  _renderEmoji(ctx, emoji, sx, sy, cs) {
    ctx.font = `${cs - 4}px serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillStyle = '#fff';
    ctx.fillText(emoji, sx + cs / 2, sy + cs / 2 + 1);
  }

  _renderMinimap(ctx, w, h) {
    const mmSize = 80;
    const mmX = w - mmSize - 8;
    const mmY = h - mmSize - 8;
    const scale = mmSize / CONST.TOTAL_SIZE;

    ctx.fillStyle = 'rgba(0,0,0,0.6)';
    ctx.fillRect(mmX - 2, mmY - 2, mmSize + 4, mmSize + 4);

    for (let y = 0; y < CONST.TOTAL_SIZE; y++) {
      for (let x = 0; x < CONST.TOTAL_SIZE; x++) {
        const terrain = this.mapData.getTerrain(x, y);
        const farm = this.mapData.getFarmState(x, y);
        if (farm && farm.state !== FarmTileState.NONE) {
          ctx.fillStyle = farm.state === FarmTileState.PLANTED ? '#c0a030' : '#8B6914';
        } else {
          ctx.fillStyle = TerrainColors[terrain] || '#333';
        }
        ctx.fillRect(mmX + x * scale, mmY + y * scale, Math.ceil(scale), Math.ceil(scale));
      }
    }

    const vx = (-this.offsetX / this.cellSize) * scale;
    const vy = (-this.offsetY / this.cellSize) * scale;
    const vw = (w / this.cellSize) * scale;
    const vh = (h / this.cellSize) * scale;
    ctx.strokeStyle = '#e2b714';
    ctx.lineWidth = 1;
    ctx.strokeRect(mmX + vx, mmY + vy, vw, vh);
  }
}
