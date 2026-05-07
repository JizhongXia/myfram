# MyFram - 农场游戏

一个使用 Godot 4.x 开发的农场模拟游戏。

## 海水贴图测试场景

- 场景：`scenes/test/WaterTest.tscn`，脚本 `WaterTest.gd`：单层 `TileMapLayer` 铺满 `assets/sprout-lands/graphics/water/0..3.png` 四帧动画。
- 当前 `project.godot` 的 `run/main_scene` 指向该测试场景，便于单独验证海水贴图；恢复主地图请改回 `res://scenes/map/MapManager.tscn`（若已从其它分支检出完整工程）。

## 项目结构

```
myfram/
├── scenes/
│   ├── test/
│   │   ├── WaterTest.tscn
│   │   └── WaterTest.gd
│   └── map/
│       ├── terrain_types.gd      # 地形类型定义
│       ├── MapManager.gd         # 地图管理器脚本
│       └── MapManager.tscn       # 地图管理器场景
├── scripts/
│   └── map_data.gd              # 地图数据系统
├── assets/                       # 资源文件夹
└── project.godot                # Godot 项目配置
```

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
