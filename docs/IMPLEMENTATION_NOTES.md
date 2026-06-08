# IMPLEMENTATION_NOTES.md

本文件用于记录 WhyTheyFight 当前实现状态、临时实现、技术债和验证方式。

---

# 1. 当前阶段

```text
游戏管理逻辑 + 网格逻辑测试中
```

当前重点：

```text
1. 地图网格基础逻辑
2. 游戏管理逻辑
3. 后续接入地图分层、单位、建筑、行动和胜利判断
```

---

# 2. 当前已知项目配置

Godot 项目配置中曾出现：

```text
config/name="wtf2"
run/main_scene="res://tests/integration/grid/test_grid.tscn"
config/features=PackedStringArray("4.6", "Mobile")
```

已知 autoload：

```text
EventBus
GameConfig
```

---

# 3. 当前推荐实现优先级

```text
1. MapData / Grid 基础结构
2. Terrain Layer
3. Unit Layer
4. Structure Layer
5. Core
6. PlayerModel / FactionSystem
7. MovementRule
8. AttackRule / DamageRule
9. VictorySystem
10. TurnController / Action Points
```

---

# 4. 暂缓实现内容

```text
飞升胜利
复杂资源经济
战争迷雾
遗物
高级技能
反击
动态同盟
污染
可激活单位
```

---

# 5. 实现约束

```text
1. 不要把 Terrain / Structure / Unit / Resource 混进单一 CellType。
2. 不要把核心玩法规则塞进 EventBus。
3. 不要让 Model 持有 Node 引用。
4. 不要让 Rule 直接操作场景节点。
5. 不要在设计未明确时擅自补充永久规则。

```
# 6. 补充说明
1. MapData 当前是低层分层数据容器。set_terrain / place_unit / place_structure 等方法不负责完整合法性检查。合法性检查应由 MovementRule、ConstructRule、ActionController 等上层规则完成。
---

# 7. 验证记录

每次完成一个功能后，在这里追加记录。

格式：

```markdown
## YYYY-MM-DD 功能名称

### 修改文件

- `path/to/file.gd`

### 实现内容

- ...

### 验证方式

- ...

### 未解决问题

- ...
```

---

## 2026-06-08 分层地图基础结构与可通行判断

### 修改文件

- `scripts/models/map_data.gd` (新建)
- `scripts/models/combat_entity_model.gd` (新建)
- `scripts/models/action_check_result.gd` (新建)
- `scripts/rules/movement_rule.gd` (新建)
- `tests/integration/map/test_map_data.gd` (新建)
- `tests/integration/map/test_map_data.tscn` (新建)
- `docs/IMPLEMENTATION_NOTES.md` (本文件)

### 实现内容

- 创建 MapData 分层地图数据模型，包含 5 层:
  - Terrain Layer (地形: Road / Water / Obstacle)
  - Structure Layer (建筑)
  - Unit Layer (单位)
  - Resource Layer (资源)
  - Effect Layer (效果)
- 创建 CombatEntityModel 战斗实体基础数据模型 (含 can_swim 等能力标记)
- 创建 ActionCheckResult 行动检查结果模型
- 创建 MovementRule 基础可通行判断:
  - 边界检查 → 地形检查 → 建筑阻挡 → 单位阻挡 → 效果阻挡
  - 提供 bool 和 ActionCheckResult 两种返回形式
- Road 默认可通行；Water 仅 can_swim 单位可通过；Obstacle 不可通行
- 有建筑/单位的格子默认不可通行
- 旧 GridCell/GridManager 保持不变，与 test_grid.tscn 兼容
- 创建 test_map_data.tscn 验证场景（14 项测试，60+ 断言）
- Vision Layer 在本任务中未实现（视野规则暂缓，参见 CLAUDE.md §4.2）
- CombatEntityModel.map_attr 对应设计文档中的 MAP (Magical Attack Point)，
  加 _attr 后缀以避免与 MapData 类名混淆

### 验证方式

- GDScript 语法检查（所有文件通过 Godot 4.x class_name 规范）
- test_map_data.tscn 可在 Godot 编辑器中运行以验证全部 14 项测试
- 手动逻辑审查: passability 检查是纯函数，不修改 MapData 或 CombatEntityModel 状态

### 未解决问题

- 效果层的阻挡逻辑暂为 stub（所有效果视为非阻挡），待效果系统明确后扩展
- 旧 GridCell/GridManager (scripts/grid/) 与新 MapData (scripts/models/) 并存，
  后续需要统一迁移，但这不在本次任务范围内

---

## 2026-06-08 测试目录迁移与地形接口对齐

### 修改文件

- `tests/integration/grid/test_grid.gd` (迁移、缩进修复、清除冗余 await)
- `tests/integration/grid/test_grid.tscn` (迁移、路径更新)
- `tests/integration/map/test_map_data.gd` (迁移)
- `tests/integration/map/test_map_data.tscn` (迁移、路径更新)
- `tests/integration/gameplay/test_main.gd` (迁移)
- `tests/integration/gameplay/test_main.tscn` (迁移、路径更新)
- `scripts/grid/grid_cell.gd` (新增地形映射文档 + `get_basic_terrain_type()` 桥接)
- `project.godot` (`run/main_scene` 路径更新)
- `tests/README.md` (新建)
- `.claude/skills/godot-gameplay/SKILL.md` (新增 Test Placement Rule)
- `docs/GAME_DESIGN_AGENT.md` (入口场景路径更新)
- `docs/IMPLEMENTATION_NOTES.md` (本文件)

### 测试验证状态

- `tests/integration/grid/test_grid.tscn` — ✅ 已通过（缩进修复 + 冗余 await 清理后）
- `tests/integration/map/test_map_data.tscn` — ✅ 已通过（14 项测试，60+ 断言）
- `tests/integration/gameplay/test_main.tscn` — ⚠️ 当前为占位，尚未实现

### 系统分类

| 系统 | 定位 | 地形枚举 |
|---|---|---|
| GridCell / GridManager | 旧网格系统（遗留，向后兼容） | PLAIN, FOREST, MOUNTAIN, WATER, WALL |
| MapData / MovementRule | 当前标准分层地图系统（推荐） | ROAD, WATER, OBSTACLE |

### 地形映射

```
GridCell.Terrain        →  MapData.TerrainType
─────────────────────────────────────────────
PLAIN   (0)             →  ROAD      (0)
FOREST  (1)             →  ROAD      (0)   [扩展: 掩体, 消耗 1.5]
MOUNTAIN(2)             →  ROAD      (0)   [扩展: 高地, 消耗 2.0]
WATER   (3)             →  WATER     (1)
WALL    (4)             →  OBSTACLE  (2)
```

FOREST / MOUNTAIN 是 GridCell 遗留系统独有的扩展地形类型，在 MapData 分层系统中暂无直接对应。
其基础通行判断等价于 ROAD，额外属性（掩体/高地/移动消耗）通过 GridCell 的特化方法提供。

### 临时兼容桥接

`GridCell.get_basic_terrain_type() -> int` 返回 MapData.TerrainType 对应的整数值 (0/1/2)，
供需要在两套系统间转换的代码使用。后续新玩法逻辑应优先使用 MapData + MovementRule。

### 验证方式

- 全项目旧路径引用扫描（`res://test_grid.*` 等 6 个旧路径），除 `.godot/editor/` 自动生成文件外已清零
- 3 个 `.tscn` 的 `ext_resource path` 全部指向存在的 `.gd` 文件
- 生产目录（`scripts/`、根目录等）无测试文件散落
- `test_grid.gd` 仅剩 2 个合法 `await get_tree().process_frame`，无 REDUNDANT_AWAIT

### 未解决问题

- 两套通行判断系统（GridManager.is_cell_walkable vs MovementRule.can_unit_enter）长期共存，
  后续应逐步将 A* 寻路等逻辑迁移到 MapData 分层系统
- FOREST / MOUNTAIN 扩展地形在 MapData 中的表达方式待设计明确

---

# 7. 测试文件布局策略

依据 CLAUDE.md §8 Test File Rules，所有测试文件必须放在 `tests/` 目录下。

当前测试文件布局：

```text
tests/
  integration/
    grid/       — test_grid.gd / test_grid.tscn (GridCell + GridManager)
    map/        — test_map_data.gd / test_map_data.tscn (MapData + MovementRule)
    gameplay/   — test_main.gd / test_main.tscn (GameManager)
  unit/         — 预留: 模型和规则单元测试
  scenes/       — 预留: 场景测试
  fixtures/     — 预留: 测试夹具
```

规则：
- 测试代码不得混入 `scripts/`、`scenes/`、`autoload/` 等生产目录。
- 生产代码可以被测试引用，但生产代码不得依赖 `tests/` 下的文件。

---

# 8. 临时决策记录

当为了推进原型需要采用临时规则时，在这里记录。

格式：

```markdown
## 决策编号：TEMP-001

### 临时规则

...

### 使用原因

...

### 需要后续确认的问题

...

### 是否允许 agent 扩展

否
```

## 决策编号：TEMP-001

### 临时规则

所有建筑默认阻挡单位移动。MovementRule 在检查到单元格存在建筑时直接返回不可通行，
不区分建筑类型。

### 使用原因

OPEN_QUESTIONS.md §5 Q5 "建筑是否阻挡移动？" 尚未有明确设计结论。
本任务明确要求"有阻挡建筑的格子默认不可通行"，因此在 prototype 阶段采用
"所有建筑阻挡"的默认规则。

### 需要后续确认的问题

- 是否存在不阻挡移动的建筑类型（如装饰性建筑、可通过的废墟）？
- 是否需要 is_blocking 属性来区分建筑类型？
- 盟友建筑是否允许穿过？

### 是否允许 agent 扩展

否。此规则需等待设计明确后才能修改。
