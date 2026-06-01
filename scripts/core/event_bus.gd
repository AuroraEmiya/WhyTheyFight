# ============================================================
# EventBus - 全局信号总线（单例 Autoload）
# ============================================================
# 用法:
#   发送方: EventBus.turn_changed.emit(player_id)
#   接收方: EventBus.turn_changed.connect(_on_turn_changed)
#
# 配置:
#   项目设置 → Autoload → Path: res://scripts/core/event_bus.gd
#   Node Name: EventBus
# ============================================================
extends Node

# ──────────────────────────────────────────
# 游戏流程信号
# ──────────────────────────────────────────
signal game_started
signal game_ended(winner: int)  # 1:玩家1, 2:玩家2, 3:BOSS
signal turn_changed(player_id: int)

# ──────────────────────────────────────────
# 战斗事件
# ──────────────────────────────────────────
signal unit_damaged(unit: Node, damage: int, source: Node)
signal unit_destroyed(unit: Node)
signal building_destroyed(building: Node)

# ──────────────────────────────────────────
# 单位事件
# ──────────────────────────────────────────
signal unit_deployed(unit: Node, position: Vector2)
signal unit_moved(unit: Node, from: Vector2, to: Vector2)
signal unit_upgraded(unit: Node, upgrade_type: String)

# ──────────────────────────────────────────
# 采集事件
# ──────────────────────────────────────────
signal resource_harvested(unit: Node, amount: int, resource_type: String)

# ──────────────────────────────────────────
# 网格事件
# ──────────────────────────────────────────
signal grid_ready
signal grid_cell_updated(position: Vector2i)

# ──────────────────────────────────────────
# UI事件
# ──────────────────────────────────────────
signal ui_refresh_needed()


func _ready() -> void:
	print("[EventBus] ✅ 全局信号总线已初始化")
