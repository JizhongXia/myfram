# H5 平台场景（Vue 3 + Node + SQLite + Docker）

本仓库在分支 `cursor/h5-vue-game-rebuild-e2a1` 上从零重建：前端为 **Vue 3 + Vite**，游戏层使用 **Phaser 3**（可继续引入其他包）；后端为 **Express + better-sqlite3**；编排为 **Docker Compose**。

## 初始场景

- **平台**：可站立的地面与一块高台（矩形碰撞体）。
- **路灯**：精灵图路径为 `client/public/assets/lamp.png`（你可自行替换为 `路灯.png` 内容，保持文件名或改 `GameScene.js` 中的 `load.image`）。
- **核心**：带呼吸缩放的圆形目标物。
- **人物移动**：左右 **A/D** 或方向键，**W** 或上键在着地时跳跃；位置会周期性写入 SQLite（`/api/state/player`）。

## 本地开发

```bash
npm install
npm run dev
```

浏览器打开 Vite 提示的地址（默认 `http://localhost:5173`）。`/api` 由 Vite 代理到 `http://127.0.0.1:3001`。

## 测试

```bash
npm test
```

包含客户端 Vitest 与 API 的 Node 内置测试。

## Docker（本机需安装 Docker）

```bash
docker compose up --build
```

前端映射 **8080**，API 映射 **3001**；SQLite 数据卷挂载在 API 容器的 `/data`。

## 技术说明

Phaser 体积较大，生产构建会有 chunk 体积提示；后续可用 `import()` 懒加载 Phaser 场景以优化首包。
