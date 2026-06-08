# CLAUDE.md

本文件是 WhyTheyFight 项目的 Claude Code 项目级长期规则。

Claude Code / coding agent 在修改本项目代码前，应优先阅读本文件，并根据任务需要继续阅读 `docs/` 下的设计文档。

---

## 1. Project

项目名称：

```text
WhyTheyFight
```

项目类型：

```text
Godot 4.x 2D grid-based Real Turn Strategy prototype
```

当前阶段：

```text
游戏管理逻辑 + 网格逻辑测试中
```

当前设计方向：

```text
沙盘战争 + 回合制战斗 + RTS 资源运营与单位调度
```

核心目标：

```text
保留策略深度与自由度，避免传统 RTS 对手速、多线操作和高频微操的强依赖。
```

---

## 2. Required Reading

执行 gameplay、地图、单位、行动、战斗、资源、回合、胜利条件相关任务前，必须阅读：

```text
docs/GAME_DESIGN_AGENT.md
docs/OPEN_QUESTIONS.md
docs/IMPLEMENTATION_NOTES.md
```

如果任务偏向玩法共识或设计解释，也应阅读：

```text
docs/GAME_DESIGN_DEVELOPER.md
docs/PROJECT_INTRO.md
```

---

## 3. Architecture Rules

### 3.1 分层原则

Godot 实现应保持以下分层：

```text
models/
- 保存运行时数据
- 不依赖场景节点
- 不直接操作 UI

rules/
- 计算玩法规则
- 尽量保持纯逻辑
- 不直接操作 Node2D、Control 或场景路径

systems/
- 管理跨对象系统，例如胜利判断、阵营关系、视野、地图生成

controllers/
- 串联输入、规则、状态和表现
- 管理流程推进

nodes/
- 负责场景表现、动画、点击区域、视觉更新
- 不承载复杂玩法规则

autoload/
- EventBus 用于事件通知
- GameConfig 用于全局配置
```

### 3.2 地图分层规则

不要把地形、建筑、单位、资源混在一个 `CellType` 中。

正确结构：

```text
Terrain Layer    地形层
Structure Layer  建筑层
Unit Layer       单位层
Resource Layer   资源层
Vision Layer     视野层
Effect Layer     效果层
```

### 3.3 EventBus 使用规则

`EventBus` 只用于事件通知，不用于承载核心规则。

允许：

```text
unit_selected
unit_moved
unit_attacked
unit_damaged
unit_destroyed
structure_constructed
core_destroyed
resource_gathered
turn_started
turn_ended
victory_triggered
```

禁止把以下逻辑塞进 `EventBus`：

```text
完整战斗结算
完整回合推进
完整胜利判断
完整资源生产
地图生成
```

---

## 4. Gameplay Implementation Rules

### 4.1 不要擅自补全永久规则

当设计文档未定义某个机制时，不要自行设计完整永久规则。

不要擅自补全：

```text
反击
飞升胜利条件
资源产出公式
Core 生产能力
单位生产系统
同盟胜利
战争迷雾记忆
污染机制
遗物效果
技能细节
```

正确处理方式：

```text
1. 只实现用户明确要求的最小行为；
2. 若必须记录假设，写入 docs/OPEN_QUESTIONS.md；
3. 不把临时假设扩展为全局规则。
```

### 4.2 优先实现基础闭环

当前实现优先级：

```text
1. 地图网格
2. 地形层
3. 单位层
4. 建筑层
5. Core
6. Player / Faction
7. 基础移动
8. 基础攻击
9. 基础胜利判断
10. 基础行动点
```

暂缓：

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

## 5. Coding Rules

- 优先使用 typed GDScript。
- 优先局部修改，不做无关重构。
- 不要为了小功能重写大文件。
- 新增玩法规则前，先检查 `docs/GAME_DESIGN_AGENT.md`。
- 设计不明确时，更新 `docs/OPEN_QUESTIONS.md`，不要自行补齐规则。
- Node 脚本只负责表现、输入转发和场景集成。
- Rule 脚本负责确定性玩法逻辑。
- Model 不应持有 Node 引用或场景路径。
- Controller 可以协调系统，但不应隐藏复杂规则计算。

---

## 6. Verification

修改 gameplay 代码后，应尽量完成：

```text
1. 检查 GDScript 语法；
2. 检查相关场景是否能加载；
3. 验证改动是否符合 docs/GAME_DESIGN_AGENT.md；
4. 记录改动文件；
5. 记录验证方式；
6. 记录未解决风险。
```

---

## 7. Output Expectations

完成任务后，向用户报告：

```text
1. 修改了哪些文件；
2. 实现了什么行为；
3. 依据了哪条设计规则；
4. 做了哪些验证；
5. 哪些问题仍未决。
```


## 8. Test File Rules

All test-related files must be placed under the `tests/` directory.

Test files include:

```text
test scripts
test scenes
test fixtures
mock data
temporary test resources
debug-only test maps

Do not place test-only files under production directories such as:

scripts/
scenes/
autoload/
data/

unless the file is part of the actual runtime game.

Production code may be imported by tests, but production code must not depend on files under tests/.

Recommended test structure:

tests/
  unit/
    models/
    rules/
    systems/

  integration/
    gameplay/
    map/
    action/

  scenes/
    test_grid/
    test_movement/
    test_combat/

  fixtures/
    maps/
    units/
    resources/

When adding new tests, mirror the production system being tested.


---
