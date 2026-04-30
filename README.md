# H5 牧场原型（Vue 3 + Node + SQLite + Docker）

前端为 **Vue 3 + Vite**，游戏层为 **Phaser 3**；后端 **Express + better-sqlite3**；**Docker Compose** 编排。

## Sprout Lands 美术与地图

- 推荐资源：[Sprout Lands - Asset Pack](https://cupnooble.itch.io/sprout-lands-asset-pack)（itch.io）。
- 当前仓库在 `client/public/assets/sprout-lands/` 下附带了一套与 Sprout Lands 兼容的 **地图与贴图**（来自开源教程仓库 [magicjulio/sproutland](https://github.com/magicjulio/sproutland)，其 README 已署名为 Cup Nooble）。**若用于商业发行，请替换为你从 itch 下载的官方包，并遵守许可与署名。**
- 构建时会运行 `client/scripts/build-sprout-manifest.mjs`，从 `map.tmx` 生成 `client/src/generated/sprout-manifest.json`，供 Phaser 加载瓦片与物体。

## 玩法（当前）

- **俯视牧场地图**：草地、装饰、房屋、围栏、树木等；**碰撞层**来自 Tiled 的 Collision 图层。
- **「核心」**：使用苹果精灵作为可收集物占位，带缩放呼吸动画。
- **移动**：**WASD** 或方向键**四方向**行走；角色使用包内四向行走帧动画。位置仍会周期性同步到 SQLite（`/api/state/player`）。

## 本地开发

```bash
npm install
npm run dev
```

浏览器打开 Vite 地址（默认 `http://localhost:5173`）。`/api` 由 Vite 代理到 `http://127.0.0.1:3001`。

## 测试

```bash
npm test
```

## Docker（本机需安装 Docker）

```bash
docker compose up --build
```

前端 **8080**，API **3001**；SQLite 数据卷在 API 容器的 `/data`。

## 技术说明

Phaser 首包较大；后续可用 `import()` 懒加载场景以减小首屏 JS。
