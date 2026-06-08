---
name: godot-gameplay
description: Implement or modify Godot gameplay features in WhyTheyFight according to the project design documents and architecture rules.
---

# Godot Gameplay Implementation Skill

Use this skill when implementing, modifying, or reviewing gameplay behavior in the WhyTheyFight Godot project.

---

# Required Reading

Before editing gameplay code, read:

```text
CLAUDE.md
docs/GAME_DESIGN_AGENT.md
docs/OPEN_QUESTIONS.md
docs/IMPLEMENTATION_NOTES.md
```

If the task involves high-level design or README-facing explanation, also read:

```text
docs/GAME_DESIGN_DEVELOPER.md
docs/PROJECT_INTRO.md
```

---

# Implementation Process

## 1. Identify the gameplay concept

Classify the task as one or more of:

```text
map
terrain
spawn_space
unit
structure
core
resource
movement
attack
damage
construction
vision
turn flow
action point
victory
UI interaction
```

---

## 2. Locate the correct layer

Use the correct layer:

```text
models/
- runtime data

rules/
- deterministic gameplay calculations

systems/
- global systems such as victory, faction, vision, map generation

controllers/
- flow coordination

nodes/
- visual representation and scene integration

autoload/
- EventBus and GameConfig only
```

Do not put rules into visual nodes.

Do not put full gameplay resolution into EventBus.

---

## 3. Check design coverage

Before implementing, check whether the behavior is defined in:

```text
docs/GAME_DESIGN_AGENT.md
docs/OPEN_QUESTIONS.md
```

If undefined:

```text
1. Do not invent a permanent rule.
2. Implement only the explicitly requested minimal behavior.
3. Add a question to docs/OPEN_QUESTIONS.md if needed.
```

---

## 4. Preserve map layering

Never implement map state as a single `CellType` that includes terrain, units, structures, and resources.

Use or preserve this conceptual separation:

```text
Terrain Layer
Structure Layer
Unit Layer
Resource Layer
Vision Layer
Effect Layer
```

---

## 5. Prefer local changes

Make the smallest necessary change.

Do not rewrite large files unless the user explicitly requests a rewrite or the file is very small and simple.

Do not rename unrelated files.

Do not migrate the whole project structure for a small gameplay change.

---

# Action Implementation Template

When implementing a gameplay action, define or preserve:

```text
1. Input
2. Preconditions
3. Cost
4. Result
5. Failure result
6. Events
7. Verification method
```

Recommended action methods:

```gdscript
func can_execute_action(action: GameAction, game_state: GameState) -> ActionCheckResult:
    pass

func execute_action(action: GameAction, game_state: GameState) -> ActionResult:
    pass
```

---

# Current Priority

Prioritize:

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

Defer unless explicitly requested:

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

---

# Verification

After changes, report:

```text
1. Files changed
2. Behavior implemented
3. Design rule followed
4. Verification performed
5. Remaining risks or unresolved questions
```

If no runtime verification was possible, state that clearly.

---

# Test Placement Rule

When creating or modifying tests, place all test-related files under:

```text
tests/

This includes:

test scripts
test scenes
fixtures
mock data
temporary test resources
debug-only test maps

Do not add test-only files to production directories such as:

scripts/
scenes/
autoload/
data/

Production code can be tested from tests/, but production code must not import or depend on tests/.