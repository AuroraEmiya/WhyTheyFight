# ============================================================
# CombatEntityModel - 战斗实体基础数据模型
# ============================================================
# 类型: RefCounted（纯数据，不依赖场景节点）
#
# 为可移动单位和可攻击建筑提供共享基础概念。
# 设计依据: docs/GAME_DESIGN_AGENT.md §7.4
# ============================================================
class_name CombatEntityModel
extends RefCounted


# ──────────────────────────────────────────
# 身份
# ──────────────────────────────────────────
var entity_id: int = -1
var owner_player_id: int = -1
var cell: Vector2i = Vector2i.ZERO


# ──────────────────────────────────────────
# 战斗属性
# ──────────────────────────────────────────
var hp: int = 1
var max_hp: int = 1

var sp: int = 0
var max_sp: int = 0

var pdp: int = 0    # Physical Defense Point
var mdp: int = 0    # Magical Defense Point
var pap: int = 0    # Physical Attack Point
var map_attr: int = 0  # Magical Attack Point (避免与 MapData 冲突，加 _attr 后缀)

var attack_range: int = 1
var mobility: int = 0


# ──────────────────────────────────────────
# 能力标记
# ──────────────────────────────────────────
var can_move: bool = false
var can_attack: bool = false
var can_gather: bool = false
var can_construct: bool = false
var can_defend: bool = false
var can_use_skill: bool = false
var can_swim: bool = false
var can_provide_vision: bool = false


# ──────────────────────────────────────────
# 回合状态
# ──────────────────────────────────────────
var has_acted_this_turn: bool = false
var status_tags: Array[String] = []


# ──────────────────────────────────────────
# 便捷方法
# ──────────────────────────────────────────

## 判断实体是否存活
func is_alive() -> bool:
	return hp > 0


## 为该实体设置一个基本属性集（用于原型测试）
func configure_basic(hp_val: int, atk: int, mov: int) -> void:
	max_hp = hp_val
	hp = hp_val
	pap = atk
	mobility = mov
	can_move = true
	can_attack = true


func _to_string() -> String:
	return "CombatEntity(id=%d, player=%d, cell=%s, hp=%d/%d, can_swim=%s)" % [
		entity_id, owner_player_id, cell, hp, max_hp, can_swim
	]
