(() => {
  const canvas = document.getElementById('game-canvas');
  const game = new Game();
  const renderer = new Renderer(canvas, game.mapData);

  let scrollSpeed = 8;
  let keysDown = {};
  let animFrame;

  function centerView() {
    const cx = CONST.TOTAL_SIZE * CONST.CELL_PX / 2;
    const cy = CONST.TOTAL_SIZE * CONST.CELL_PX / 2;
    renderer.setView(
      canvas.width / 2 - cx,
      canvas.height / 2 - cy
    );
  }

  function resizeCanvas() {
    renderer._resize();
    render();
  }

  function render() {
    renderer.render();
  }

  function gameLoop() {
    let moved = false;
    if (keysDown['ArrowLeft']  || keysDown['a'] || keysDown['A']) { renderer.offsetX += scrollSpeed; moved = true; }
    if (keysDown['ArrowRight'] || keysDown['d'] || keysDown['D']) { renderer.offsetX -= scrollSpeed; moved = true; }
    if (keysDown['ArrowUp']    || keysDown['w'] || keysDown['W']) { renderer.offsetY += scrollSpeed; moved = true; }
    if (keysDown['ArrowDown']  || keysDown['s'] || keysDown['S']) { renderer.offsetY -= scrollSpeed; moved = true; }
    if (moved) render();
    animFrame = requestAnimationFrame(gameLoop);
  }

  function updateUI() {
    document.getElementById('clock').textContent = `第 ${game.day} 天 · ${game.getSeasonName()}`;
    document.getElementById('gold').textContent = `💰 ${game.gold}`;
    updateInventoryUI();
    updateSeedUI();
    updateLogUI();
  }

  function updateCellInfo(result) {
    const el = document.getElementById('cell-info');
    if (!result) { el.textContent = '点击地图上的格子查看信息'; return; }

    if (result.action === 'inspect') {
      const terrain = TerrainNames[result.terrain] || '?';
      const emoji = TerrainEmoji[result.terrain] || '';
      let html = `<b>${emoji} ${terrain}</b><br>`;
      html += `坐标: (${result.x}, ${result.y})<br>`;
      html += `区域: ${result.area}<br>`;
      if (result.farm) {
        html += `<br>🌾 ${result.farm.getDescription()}`;
      }
      el.innerHTML = html;
    } else if (result.action === 'error') {
      el.innerHTML = `<span style="color:#ff6b6b">❌ ${result.msg}</span>`;
    } else if (result.action === 'need_seed') {
      el.innerHTML = '<span style="color:#e2b714">请在下方选择种子类型</span>';
      document.getElementById('seed-select').classList.remove('hidden');
    } else {
      el.innerHTML = `✅ 操作成功`;
    }
  }

  function updateInventoryUI() {
    const grid = document.getElementById('inventory-grid');
    grid.innerHTML = '';
    for (let i = 0; i < game.inventory.size; i++) {
      const slot = game.inventory.slots[i];
      const div = document.createElement('div');
      div.className = 'inv-slot';
      if (slot) {
        const def = ItemDefs[slot.id];
        div.innerHTML = `${def ? def.emoji : '?'}<span class="count">${slot.count}</span>`;
        div.title = `${def ? def.name : slot.id} ×${slot.count}`;
        div.addEventListener('click', () => onSlotClick(i, slot));
      }
      grid.appendChild(div);
    }
  }

  function onSlotClick(index, slot) {
    if (!slot) return;
    const def = ItemDefs[slot.id];
    if (def && def.type === 'seed') {
      game.setSeed(slot.id);
      game.setTool('seed');
      setActiveTool('seed');
      game.log(`选择了${def.name}作为当前种子`, 'info');
      updateUI();
    } else if (def && def.sellPrice) {
      const result = game.sellItem(slot.id, 1);
      if (result.success) updateUI();
    } else {
      game.log(`${def ? def.name : slot.id}: 无特殊操作`, 'info');
      updateLogUI();
    }
  }

  function updateSeedUI() {
    const container = document.getElementById('seed-list');
    const seeds = game.inventory.getSeeds();
    container.innerHTML = '';

    if (seeds.length === 0) {
      container.innerHTML = '<div style="color:#888;font-size:12px">没有种子</div>';
      return;
    }

    document.getElementById('seed-select').classList.remove('hidden');

    for (const seedId of seeds) {
      const def = ItemDefs[seedId];
      const count = game.inventory.countItem(seedId);
      const div = document.createElement('div');
      div.className = 'seed-option' + (game.selectedSeed === seedId ? ' selected' : '');
      const cropDef = def.cropId ? CropDefs[def.cropId] : null;
      div.innerHTML = `${cropDef ? cropDef.emoji : '🌱'} ${def.name} ×${count}`;
      div.addEventListener('click', () => {
        game.setSeed(seedId);
        updateSeedUI();
        game.log(`选择了${def.name}`, 'info');
        updateLogUI();
      });
      container.appendChild(div);
    }
  }

  function updateLogUI() {
    const el = document.getElementById('game-log');
    el.innerHTML = game.logs.slice(0, 20).map(l =>
      `<div class="log-entry ${l.type}"><small>[D${l.day}]</small> ${l.msg}</div>`
    ).join('');
  }

  function setActiveTool(tool) {
    game.setTool(tool);
    document.querySelectorAll('.tool-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.tool === tool);
    });
  }

  // --- Event handlers ---

  canvas.addEventListener('click', (e) => {
    const rect = canvas.getBoundingClientRect();
    const sx = e.clientX - rect.left;
    const sy = e.clientY - rect.top;
    const cell = renderer.screenToCell(sx, sy);

    if (cell.x < 0 || cell.x >= CONST.TOTAL_SIZE || cell.y < 0 || cell.y >= CONST.TOTAL_SIZE) return;

    renderer.selectedCell = cell;
    const result = game.handleClick(cell.x, cell.y);
    updateCellInfo(result);
    updateUI();
    render();
  });

  canvas.addEventListener('mousemove', (e) => {
    const rect = canvas.getBoundingClientRect();
    const sx = e.clientX - rect.left;
    const sy = e.clientY - rect.top;
    const cell = renderer.screenToCell(sx, sy);

    if (cell.x >= 0 && cell.x < CONST.TOTAL_SIZE && cell.y >= 0 && cell.y < CONST.TOTAL_SIZE) {
      renderer.hoveredCell = cell;
      const tooltip = document.getElementById('tooltip');
      const terrain = game.mapData.getTerrain(cell.x, cell.y);
      const farm = game.mapData.getFarmState(cell.x, cell.y);
      let text = `(${cell.x},${cell.y}) ${TerrainNames[terrain] || '?'}`;
      if (farm && farm.state !== FarmTileState.NONE) {
        text += ` · ${farm.getDescription()}`;
      }
      tooltip.textContent = text;
      tooltip.classList.remove('hidden');
      tooltip.style.left = (e.clientX - canvas.parentElement.getBoundingClientRect().left + 12) + 'px';
      tooltip.style.top = (e.clientY - canvas.parentElement.getBoundingClientRect().top - 30) + 'px';
    } else {
      renderer.hoveredCell = null;
      document.getElementById('tooltip').classList.add('hidden');
    }
    render();
  });

  canvas.addEventListener('mouseleave', () => {
    renderer.hoveredCell = null;
    document.getElementById('tooltip').classList.add('hidden');
    render();
  });

  canvas.addEventListener('wheel', (e) => {
    e.preventDefault();
    const zoomFactor = e.deltaY > 0 ? 0.9 : 1.1;
    const newSize = Math.max(8, Math.min(64, Math.round(renderer.cellSize * zoomFactor)));
    if (newSize !== renderer.cellSize) {
      const rect = canvas.getBoundingClientRect();
      const mx = e.clientX - rect.left;
      const my = e.clientY - rect.top;
      const worldX = (mx - renderer.offsetX) / renderer.cellSize;
      const worldY = (my - renderer.offsetY) / renderer.cellSize;
      renderer.cellSize = newSize;
      renderer.offsetX = mx - worldX * newSize;
      renderer.offsetY = my - worldY * newSize;
      render();
    }
  }, { passive: false });

  document.addEventListener('keydown', (e) => {
    keysDown[e.key] = true;

    const toolKey = CONST.TOOL_KEYS[e.key.toLowerCase()];
    if (toolKey) {
      setActiveTool(toolKey);
      updateUI();
    }

    if (e.key === 'i' || e.key === 'I') {
      const panel = document.getElementById('inventory-panel');
      panel.style.display = panel.style.display === 'none' ? '' : 'none';
    }

    if (e.key === ' ') {
      e.preventDefault();
      game.advanceDay();
      updateUI();
      render();
    }
  });

  document.addEventListener('keyup', (e) => {
    keysDown[e.key] = false;
  });

  document.querySelectorAll('.tool-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      setActiveTool(btn.dataset.tool);
      updateUI();
    });
  });

  window.addEventListener('resize', resizeCanvas);

  // --- Init ---
  centerView();
  game.log('🌾 欢迎来到 MyFram 农场！', 'action');
  game.log('使用工具栏操作：锄头翻土 → 播种 → 浇水 → 等待生长 → 收获', 'info');
  game.log('按 Space 进入下一天，作物会根据浇水情况生长', 'info');
  updateUI();
  gameLoop();
})();
