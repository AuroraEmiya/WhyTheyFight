# WhyTheyFight Agent Specification

本文件供 Claude Code / coding agent / 自动化开发助手阅读。

目标是让 agent 理解当前游戏设计、实现边界、数据分层、接口方向和禁止擅自补全的内容。

---

# 0. Project Context

项目名称：

```text
WhyTheyFight
```

项目类型：

```text
Godot 4.x 2D grid-based Real Turn Strategy prototype
```

当前开发进度：

```text
游戏管理逻辑 + 网格逻辑测试中
```

当前已知入口场景：

```text
res://tests/integration/grid/test_grid.tscn
```

当前已知 autoload：

```text
EventBus
GameConfig
```

---

# 1. Core Design Summary

WhyTheyFight is a turn-based strategy game combining:

```text
1. Sandbox war
2. Turn-based combat
3. RTS-style resource operation and unit coordination
```

The game should avoid traditional RTS hand-speed competition.

The intended focus is:

```text
strategic planning
resource allocation
unit coordination
terrain judgment
attack / defense timing
victory route choice
```

Temporary genre name:

```text
Real Turn Strategy
```

---

# 2. Hard Architecture Rule: Map Must Be Layered

Do not implement the map as a single `CellType` containing terrain, buildings, units, and resources.

Incorrect model:

```text
CellType:
- Road
- Core
- Tower
- MovingUnit
- Resource
```

Correct model:

```text
Terrain Layer    terrain of the cell
Structure Layer  buildings / immobile structures
Unit Layer       movable units
Resource Layer   resources / interactable resource objects
Vision Layer     player-specific visibility
Effect Layer     pollution, blessing, curse, fire, etc.
```

A cell may contain multiple layers at once.

---

# 3. Naming Rules

Use corrected terms below.

| Avoid | Use |
|---|---|
| Terrent | Structure / Building / Tower |
| Attack Arrange | Attack Range |
| Phisical | Physical |
| Demage | Damage |
| Stuned | Stunned |
| Magical Attack Point as MDP | MAP |
| TowerEnd / UnitEnd / ResourcesEnd | Avoid unless enum sentinel is explicitly needed |

Recommended attributes:

```text
HP   Health Point
SP   Skill Point
PDP  Physical Defense Point
MDP  Magical Defense Point
PAP  Physical Attack Point
MAP  Magical Attack Point
AR   Attack Range
MOV  Mobility per turn
```

---

# 4. Current Design Facts

```text
1. The game is turn-based or turn-like, not traditional real-time RTS.
2. The game keeps RTS-style resource operation, unit production, deployment, and combat coordination.
3. The map and spawn_space should be procedurally or algorithmically generated.
4. Map size is currently planned as 100 * 100.
5. The game supports at least two players.
6. Default faction count equals player count.
7. Temporary alliances and betrayal are not forbidden by design.
8. Base victory is achieved by destroying all enemy cores.
9. Ascension victory is planned for later but not currently specified.
10. Target game duration is 30 minutes to 1 hour.
```

---

# 5. Do Not Invent Permanent Rules

If a system is not defined in this document, do not implement a complete permanent rule.

Do not invent permanent rules for:

```text
counterattack
ascension victory condition
resource production formula
core production ability
unit production system
alliance victory
fog of war memory
pollution mechanics
relic effects
skill details
```

Correct behavior:

```text
1. Implement only the minimal behavior explicitly requested.
2. If design is ambiguous, add an item to docs/OPEN_QUESTIONS.md.
3. Do not turn temporary assumptions into global gameplay rules.
```

---

# 6. Recommended Godot Folder Structure

```text
res://
  docs/
    PROJECT_INTRO.md
    GAME_DESIGN_DEVELOPER.md
    GAME_DESIGN_AGENT.md
    OPEN_QUESTIONS.md
    IMPLEMENTATION_NOTES.md

  autoload/
    event_bus.gd
    game_config.gd

  scripts/
    models/
      game_state.gd
      player_model.gd
      faction_model.gd
      combat_entity_model.gd
      unit_model.gd
      structure_model.gd
      resource_node_model.gd
      map_data.gd
      spawn_space.gd

    rules/
      movement_rule.gd
      attack_rule.gd
      damage_rule.gd
      gather_rule.gd
      construct_rule.gd
      vision_rule.gd
      victory_rule.gd
      faction_rule.gd

    systems/
      map_generator.gd
      faction_system.gd
      victory_system.gd
      vision_system.gd

    controllers/
      game_controller.gd
      turn_controller.gd
      action_controller.gd
      input_controller.gd

    nodes/
      grid_node.gd
      unit_node.gd
      structure_node.gd
      core_node.gd
      resource_node.gd
```

This structure is a recommendation, not a mandatory full migration target for a single small task.

---

# 7. Data Model Direction

## 7.1 GameState

```gdscript
class_name GameState
extends RefCounted

var map_data: MapData
var players: Dictionary
var factions: FactionSystem
var units: Dictionary
var structures: Dictionary
var resources: Dictionary
var current_player_id: int
var turn_index: int
```

## 7.2 MapData

```gdscript
class_name MapData
extends RefCounted

var width: int
var height: int

var terrain_layer: Dictionary
var structure_layer: Dictionary
var unit_layer: Dictionary
var resource_layer: Dictionary
var effect_layer: Dictionary

func is_inside(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height
```

## 7.3 PlayerModel

```gdscript
class_name PlayerModel
extends RefCounted

var player_id: int
var faction_id: int
var core_id: int
var action_points: int
var is_eliminated: bool = false
```

## 7.4 CombatEntityModel

Use a shared base concept for both movable units and attackable structures.

```gdscript
class_name CombatEntityModel
extends RefCounted

var entity_id: int
var owner_player_id: int
var cell: Vector2i

var hp: int
var max_hp: int

var sp: int
var max_sp: int

var pdp: int
var mdp: int
var pap: int
var map: int

var attack_range: int
var mobility: int

var can_move: bool = false
var can_attack: bool = false
var can_gather: bool = false
var can_construct: bool = false
var can_defend: bool = false
var can_use_skill: bool = false
var can_swim: bool = false
var can_provide_vision: bool = false

var has_acted_this_turn: bool = false
var status_tags: Array[String] = []
```

---

# 8. Action System

## 8.1 Core Rule

Each player has action points.

```text
action_points = x
```

Current accepted direction:

```text
1. Each player receives action points per turn.
2. Deploying units costs action points.
3. Constructing structures costs action points.
4. Executing actions may cost action points.
5. A unit can receive one main command during its action turn.
```

Recommended prototype rule:

```text
Each unit can execute at most one main action per turn.
Player action points limit the total number of actions in the turn.
```

---

## 8.2 GameAction

```gdscript
class_name GameAction
extends RefCounted

enum ActionType {
    MOVE,
    GATHER,
    DEFEND,
    ATTACK,
    CONSTRUCT,
    SKILL
}

var action_type: ActionType
var actor_id: int
var source_cell: Vector2i
var target_cell: Vector2i
var target_entity_id: int = -1
var structure_type: String = ""
var skill_id: String = ""
```

---

## 8.3 ActionCheckResult

```gdscript
class_name ActionCheckResult
extends RefCounted

var is_valid: bool
var reason: String

static func ok() -> ActionCheckResult:
    var result := ActionCheckResult.new()
    result.is_valid = true
    result.reason = ""
    return result

static func fail(reason: String) -> ActionCheckResult:
    var result := ActionCheckResult.new()
    result.is_valid = false
    result.reason = reason
    return result
```

---

## 8.4 ActionResult

```gdscript
class_name ActionResult
extends RefCounted

var success: bool
var reason: String
var changed_entities: Array[int] = []
var emitted_events: Array[String] = []
```

---

# 9. Action Behavior Specifications

## 9.1 MOVE

Form:

```text
MOVE(fromSrc, toDst)
```

Preconditions:

```text
1. fromSrc contains a movable unit.
2. The unit belongs to current player or controllable faction.
3. The unit is actionable.
4. toDst is inside map.
5. toDst is passable.
6. Path length <= unit.MOV.
7. Unit has not executed a main action this turn.
8. Player has enough action points.
```

Results:

```text
1. Unit position changes.
2. Player action points decrease.
3. Unit is marked as acted this turn.
4. Event unit_moved is emitted.
```

Recommended interfaces:

```gdscript
func can_move(unit_id: int, target_cell: Vector2i, game_state: GameState) -> ActionCheckResult:
    pass

func apply_move(unit_id: int, target_cell: Vector2i, game_state: GameState) -> ActionResult:
    pass
```

---

## 9.2 ATTACK

Form:

```text
ATTACK(fromSrc, toDst)
```

Preconditions:

```text
1. fromSrc contains an entity that can attack.
2. toDst contains an attackable target.
3. Attacker and target are enemies.
4. Target is within attack range.
5. Attacker is actionable.
6. Attacker has not executed a main action this turn.
7. Player has enough action points.
```

Results:

```text
1. Damage is calculated.
2. Target HP decreases.
3. If target HP <= 0, target dies or is destroyed.
4. Attacker is marked as acted this turn.
5. Events unit_attacked / unit_damaged / unit_destroyed may be emitted.
```

---

## 9.3 GATHER

Form:

```text
GATHER(fromSrc, toDst)
```

Preconditions:

```text
1. fromSrc contains a unit that can gather.
2. toDst contains a gatherable resource.
3. Unit has the required gathering capability.
4. Distance requirement is satisfied.
5. Resource remaining amount > 0.
6. Unit has not executed a main action this turn.
7. Player has enough action points.
```

Results:

```text
1. Player gains resource.
2. Resource amount decreases.
3. Unit is marked as acted this turn.
4. Resource may enter depleted state.
5. Event resource_gathered is emitted.
```

---

## 9.4 CONSTRUCT

Recommended form:

```text
CONSTRUCT(fromSrc, toDst, structure_type)
```

Preconditions:

```text
1. fromSrc contains a unit or core that can construct.
2. toDst is inside map.
3. Terrain allows construction.
4. toDst is not occupied by another unit or structure.
5. Player has enough resources.
6. Player has enough action points.
7. Constructor has not executed a main action this turn.
```

Results:

```text
1. Resources are consumed.
2. Action points are consumed.
3. Structure is created at toDst.
4. Constructor is marked as acted this turn.
5. Event structure_constructed is emitted.
```

---

## 9.5 DEFEND

Form:

```text
DEFEND(fromSrc)
```

Purpose:

```text
The unit enters defensive state and receives defense boost or damage reduction.
```

Expiration timing is not yet specified.

---

## 9.6 SKILL

Recommended form:

```text
SKILL(fromSrc, toDst, skill_id)
```

Do not invent concrete skill effects unless explicitly requested.

---

# 10. Movement Rule Interface

```gdscript
class_name MovementRule
extends RefCounted

func can_enter_cell(unit: CombatEntityModel, cell: Vector2i, game_state: GameState) -> bool:
    if not game_state.map_data.is_inside(cell):
        return false

    # 1. Check terrain passability.
    # 2. Check structure blocking.
    # 3. Check unit blocking.
    # 4. Check effects.
    return true
```

Expected check order:

```text
1. Is target cell inside map?
2. Does terrain allow this unit to enter?
3. Is there a blocking structure?
4. Is there a blocking unit?
5. Is there a blocking effect?
6. Return final passability.
```

---

# 11. Combat Rule

## 11.1 Attack Range

Attack range may use Arknights-style matrix patterns.

Example melee range:

```text
[0, 1, 0]
[1, C, 1]
[0, 1, 0]
```

Recommended interfaces:

```gdscript
func get_attackable_cells(attacker: CombatEntityModel, game_state: GameState) -> Array[Vector2i]:
    pass

func is_target_in_attack_range(attacker: CombatEntityModel, target_cell: Vector2i, game_state: GameState) -> bool:
    pass
```

---

## 11.2 Damage Formula

Prototype can use:

```text
FinalDamage = max(1, AttackPoint - DefensePoint)
```

Do not implement complex multiplier stacking unless explicitly requested.

---

## 11.3 Counterattack

Current status:

```text
Not defined.
```

Prototype recommendation:

```text
Do not implement counterattack.
Attacker resolves damage first.
If target HP <= 0, target dies or is destroyed.
```

---

# 12. Victory System

Base victory:

```text
A player wins when all enemy players' cores are destroyed.
```

Recommended interface:

```gdscript
class_name VictorySystem
extends RefCounted

func check_victory(game_state: GameState) -> VictoryResult:
    var core_result := check_core_victory(game_state)
    if core_result.has_winner:
        return core_result

    var ascension_result := check_ascension_victory(game_state)
    if ascension_result.has_winner:
        return ascension_result

    return VictoryResult.no_winner()

func check_core_victory(game_state: GameState) -> VictoryResult:
    pass

func check_ascension_victory(game_state: GameState) -> VictoryResult:
    return VictoryResult.no_winner()
```

Ascension victory must remain stubbed until explicitly designed.

---

# 13. Faction System

Do not hardcode `player_id != self_id` as the only enemy check everywhere.

Use relation query interfaces:

```gdscript
enum FactionRelation {
    SELF,
    ENEMY,
    ALLY,
    NEUTRAL
}
```

```gdscript
class_name FactionSystem
extends RefCounted

var relations: Dictionary = {}

func get_relation(source_player_id: int, target_player_id: int) -> FactionRelation:
    if source_player_id == target_player_id:
        return FactionRelation.SELF

    var key := Vector2i(source_player_id, target_player_id)
    if relations.has(key):
        return relations[key]

    return FactionRelation.ENEMY

func is_enemy(source_player_id: int, target_player_id: int) -> bool:
    return get_relation(source_player_id, target_player_id) == FactionRelation.ENEMY

func is_ally(source_player_id: int, target_player_id: int) -> bool:
    return get_relation(source_player_id, target_player_id) == FactionRelation.ALLY
```

---

# 14. EventBus Rules

EventBus is for notifications only.

Allowed examples:

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

Do not put these into EventBus:

```text
complete combat resolution
complete turn progression
complete victory logic
complete resource production
map generation
```

---

# 15. Current Implementation Priority

Prioritize the basic playable loop:

```text
1. Map grid
2. Terrain layer
3. Unit layer
4. Structure layer
5. Core
6. Player and faction
7. Basic movement
8. Basic attack
9. Basic victory check
10. Basic action points
```

Defer:

```text
ascension victory
complex resource economy
fog of war
relics
advanced skills
counterattack
alliances
pollution
activatable units
```
