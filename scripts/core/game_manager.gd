# ============================================================
# GameManager - 游戏主循环 & 回合切换
# ============================================================
# 挂载场景: 主场景根节点（非 Autoload，由场景管理生命周期）
#
# 依赖:
#   - EventBus（Autoload）: 发送 turn_changed / game_ended 信号
#   - GameConfig（Autoload）: 提供常量（行动次数等）
# ============================================================
extends Node

# ──────────────────────────────────────────
# 枚举
# ──────────────────────────────────────────
enum GameMode { PVP, PVE_COOP }
enum GamePhase { DEPLOY, ACTION, END_TURN }

# ──────────────────────────────────────────
# 状态变量
# ──────────────────────────────────────────
var current_mode: GameMode = GameMode.PVP
var current_phase: GamePhase = GamePhase.DEPLOY
var active_player_id: int = 1
var turn_count: int = 0
var is_game_over: bool = false

# 玩家数据（简单用字典存，后续替换为 BaseFaction）
var players: Dictionary = {}   # { 1: {"faction": "zerg", "base": null}, 2: {...} }


# ──────────────────────────────────────────
# 生命周期
# ──────────────────────────────────────────
func _ready() -> void:
	print("[GameManager] ✅ 游戏管理器已就绪")


# ──────────────────────────────────────────
# 公开方法
# ──────────────────────────────────────────

## 启动游戏
## @param mode: GameMode.PVP 或 GameMode.PVE_COOP
## @param player_list: Array[Dictionary] 玩家配置
func start_game(mode: GameMode, player_list: Array) -> void:
	print("[GameManager] ───── 开始新游戏 ─────")
	print("  模式: %s" % ("PVP" if mode == GameMode.PVP else "PVE合作"))
	print("  玩家数: %d" % player_list.size())

	current_mode = mode
	current_phase = GamePhase.DEPLOY
	active_player_id = 1
	turn_count = 1
	is_game_over = false
	players.clear()

	for p in player_list:
		players[p.id] = p

	EventBus.game_started.emit()
	_enter_turn(active_player_id)


## 结束当前回合，切换到下一位玩家
func end_turn() -> void:
	if is_game_over:
		print("[GameManager] ⚠️ 游戏已结束，无法结束回合")
		return

	print("[GameManager] 🔄 玩家 %d 结束回合" % active_player_id)

	current_phase = GamePhase.END_TURN

	# ── 切换玩家 ──────────────────────
	var next_player := _get_next_player_id(active_player_id)

	if next_player == 0:
		# 所有玩家已完成一轮 → 新回合
		turn_count += 1
		print("[GameManager] ─── 第 %d 回合 ───" % turn_count)
		next_player = 1  # 从玩家1重新开始

	active_player_id = next_player
	_enter_turn(active_player_id)


## 检查胜利条件（占位，后续由阵营系统接管）
## @return int: 0=继续, 1=玩家1胜, 2=玩家2胜, 3=BOSS胜
func check_victory_condition() -> int:
	# TODO: 实际逻辑——检查敌方基地是否被摧毁
	return 0


## 获取当前活跃玩家ID
func get_current_player_id() -> int:
	return active_player_id


## 获取当前回合数
func get_turn_count() -> int:
	return turn_count


# ──────────────────────────────────────────
# 内部逻辑
# ──────────────────────────────────────────

## 进入指定玩家的回合
func _enter_turn(player_id: int) -> void:
	current_phase = GamePhase.ACTION
	print("[GameManager] ▶ 玩家 %d 的回合开始（第 %d 回合）" % [player_id, turn_count])

	# 通过 EventBus 广播，所有监听方收到通知
	EventBus.turn_changed.emit(player_id)


## 获取下一位玩家ID
## PVP: 玩家1 ↔ 玩家2
## PVE: 玩家1 → 玩家2 → ... → 最后一个玩家 → 回到玩家1
## @return int: 下一位玩家ID；若本轮结束返回0
func _get_next_player_id(current_id: int) -> int:
	var next_id := current_id + 1

	if current_mode == GameMode.PVP:
		# PVP 只有两个玩家：1 和 2
		if next_id > 2:
			return 0
		return next_id
	else:
		# PVE_COOP: 可能有多个合作玩家
		if next_id > players.size():
			return 0
		return next_id


## 游戏结束
func _end_game(winner_id: int) -> void:
	is_game_over = true
	current_phase = GamePhase.END_TURN
	print("[GameManager] 🏆 游戏结束！胜者：玩家 %d" % winner_id)
	EventBus.game_ended.emit(winner_id)
