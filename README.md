# MyFram - 农场游戏

一个使用 Godot 4.x 开发的农场模拟游戏。

## 项目结构

```
myfram/
├── scenes/
│   └── map/
│       ├── terrain_types.gd      # 地形类型定义
│       ├── MapManager.gd         # 地图管理器脚本
│       └── MapManager.tscn       # 地图管理器场景
├── scripts/
│   └── map_data.gd              # 地图数据系统
├── assets/                       # 资源文件夹
│   └── sprout-lands/             # Sprout Lands 风格参考资源（见下文）
└── project.godot                # Godot 项目配置
```

## Sprout Lands 参考资源（`assets/sprout-lands/`）

与 [Sprout Lands - Asset Pack](https://cupnooble.itch.io/sprout-lands-asset-pack) 兼容的 **Tiled 地图 `data/map.tmx`** 与 **`graphics/`** 贴图已放在此目录。来源为开源教程仓库 [magicjulio/sproutland](https://github.com/magicjulio/sproutland)（其 README 署名为 Cup Nooble）。**若用于商业发行，请替换为你在 itch 购买的官方资源并遵守许可与署名。**

主场景 `MapManager` 当前为 **48×32、64px 瓦片** 的程序化世界：**海水**使用 `graphics/water/0.png`～`3.png` 横向拼成图集并循环换帧；**椭圆草地小岛**使用 `environment/Grass.png`；岛心较小椭圆为 **原始丛林**，随机放置 `objects/tree_medium.png` 与 `tree_small.png`。**角色**为 `scenes/map/player/PlayerWalk.tscn`：仅四向行走（**方向键 / WASD / 手柄左摇杆与十字键**），使用 `graphics/character/{down,left,right,up}` 序列帧，无工具动画；相机跟随玩家，移动由 `MapManager.clamp_player_world_position` 限制在岛内。手柄在 `_ready` 时注册 `move_*` 动作（含多设备 0–7 的摇杆与 D-Pad），摇杆带死区。贴图在无 `.import` 时通过 `Image.load` 读取，便于无头运行。`scripts/map_data.gd` 仍为 60×60 草地数据类，可供后续逻辑复用，与当前可视演示层独立。

## 运行项目

本仓库已包含 `assets/sprout-lands/`，克隆后 **无需再单独下载**（若需 itch 官方包可自行覆盖该目录）。

- **Godot 编辑器**：用 Godot 4.6+ 打开项目根目录，按 F5 运行（主场景 `scenes/map/MapManager.tscn`）。
- **命令行（无界面自检）**：

```bash
godot --path . --headless --quit-after 5
```

若未安装全局 `godot`，请使用你本机 Godot 可执行文件的完整路径。

## 地图系统说明

### 地图尺寸
- **核心农场区域**: 50×50 格
- **周边扩展**: 各边扩展 5 格
- **总地图尺寸**: 60×60 格

### 地形类型

地图包含以下地形类型：

| 类型 | 代码 | 说明 |
|------|------|------|
| 草地 | `GRASS` | 核心农场区域的基础地形 |
| 草地-左上角 | `GRASS_CORNER_TL` | 地图左上角 |
| 草地-右上角 | `GRASS_CORNER_TR` | 地图右上角 |
| 草地-左下角 | `GRASS_CORNER_BL` | 地图左下角 |
| 草地-右下角 | `GRASS_CORNER_BR` | 地图右下角 |
| 草地-上边 | `GRASS_EDGE_T` | 地图上边界 |
| 草地-下边 | `GRASS_EDGE_B` | 地图下边界 |
| 草地-左边 | `GRASS_EDGE_L` | 地图左边界 |
| 草地-右边 | `GRASS_EDGE_R` | 地图右边界 |

### 关键类和方法

#### MapData
主要地图数据管理类：

- `get_terrain(x, y)` - 获取指定位置的地形类型
- `set_terrain(x, y, terrain_type)` - 设置指定位置的地形类型
- `is_in_farm_area(x, y)` - 检查是否在核心农场区域
- `is_in_border_area(x, y)` - 检查是否在周边区域
- `is_corner(x, y)` - 检查是否是角落
- `is_edge(x, y)` - 检查是否是边（非角）
- `debug_print_terrain()` - 打印地形网格用于调试

#### MapManager
处理地图的渲染和交互：

- `_render_map()` - 将地形数据渲染到 TileMap
- `get_cell_under_mouse()` - 获取鼠标指向的格子
- 支持左键点击查看格子信息

## 使用方法

1. 在 Godot 中打开此项目
2. 创建 TileSet 资源（放在 `assets/` 目录）
3. 为 MapManager 场景中的 TileMap 节点分配 TileSet
4. 运行项目，地图会自动初始化并渲染

## 调试

启动游戏后，控制台会输出：
- 地图基本信息
- ASCII 艺术形式的地形网格预览
- 点击格子后的坐标和地形信息

## 下一步计划

- [ ] 创建草地 TileSet 资源
- [ ] 添加角色系统
- [ ] 实现田地耕作机制
- [ ] 添加植物生长系统
- [ ] 实现季节变化
- [ ] 添加 NPC 系统
- [ ] 开发商店和交易系统

## 许可证

MIT License
