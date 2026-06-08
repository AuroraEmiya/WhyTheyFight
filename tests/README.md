# WhyTheyFight 测试目录说明

本目录存放 WhyTheyFight 项目的所有测试相关文件。测试文件放置规则依据 `CLAUDE.md` §8 Test File Rules。

---

## 1. 核心规则

```text
1. 所有测试相关文件必须放在 tests/ 目录下。
2. 生产代码可以被 tests/ 引用，但生产代码不能依赖 tests/。
3. 不要把 test_*.gd、test_*.tscn、mock 数据或临时测试资源放到
   根目录、scripts/、scenes/、autoload/、data/ 等生产目录。
```

---

## 2. 目录结构

```text
tests/
├── README.md                  # 本文件
│
├── unit/                      # 预留: 模型、规则、系统的单元测试
│   ├── models/                #   模型单元测试
│   ├── rules/                 #   规则单元测试
│   └── systems/               #   系统单元测试
│
├── integration/               # 集成测试（当前活跃）
│   ├── grid/                  #   GridCell、GridManager 等网格集成测试
│   ├── map/                   #   MapData、MovementRule 等地图和通行规则集成测试
│   └── gameplay/              #   GameManager 或玩法流程集成测试
│
├── scenes/                    # 预留: 通用测试场景
│
└── fixtures/                  # 预留: 测试夹具（假数据）
    ├── maps/                  #   测试地图数据
    ├── units/                 #   测试单位数据
    └── resources/             #   测试资源数据
```

---

## 3. 各目录职责

### 3.1 `integration/grid/`

网格系统集成测试。当前内容：

| 文件 | 测试范围 |
|---|---|
| `test_grid.gd` | GridCell 基础、GridManager 初始化、占用系统、相邻查询、A\* 寻路 |
| `test_grid.tscn` | 测试场景入口 |

### 3.2 `integration/map/`

地图和通行规则集成测试。当前内容：

| 文件 | 测试范围 |
|---|---|
| `test_map_data.gd` | MapData 分层结构、TerrainType、MovementRule 通行判断、建筑/单位阻挡 |
| `test_map_data.tscn` | 测试场景入口 |

### 3.3 `integration/gameplay/`

玩法流程集成测试。当前内容：

| 文件 | 测试范围 |
|---|---|
| `test_main.gd` | GameManager 游戏流程（待填充） |
| `test_main.tscn` | 测试场景入口 |

### 3.4 `unit/`

预留给模型、规则、系统的独立单元测试。mirror 生产代码目录结构：
- `unit/models/` — 例如 MapData、CombatEntityModel 的单元测试
- `unit/rules/` — 例如 MovementRule 的单元测试
- `unit/systems/` — 例如 VictorySystem 的单元测试

### 3.5 `scenes/`

预留给需要独立场景的测试（如 UI 交互测试、可视化验证）。

### 3.6 `fixtures/`

预留给测试夹具数据：
- `fixtures/maps/` — 测试用地图数据
- `fixtures/units/` — 测试用单位数据
- `fixtures/resources/` — 测试用资源数据

---

## 4. 测试文件命名规范

```text
测试脚本:  test_<模块名>.gd
测试场景:  test_<模块名>.tscn
测试夹具:  <名称>_fixture.gd 或 <名称>_mock.gd
```

---

## 5. 新增测试时的规则

1. 确定测试属于单元测试还是集成测试。
2. 在对应的 `unit/` 或 `integration/` 子目录下创建文件。
3. 如果是集成测试，创建一个 `.tscn` 场景文件引用测试脚本。
4. 不要将测试文件放在生产目录（`scripts/`、`scenes/` 等）。
5. 生产代码不得 `preload` 或 `load` `tests/` 下的任何资源。
