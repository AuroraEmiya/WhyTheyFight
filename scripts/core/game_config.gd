# ============================================================
# GameConfig - 游戏常量配置（单例 Autoload）
# ============================================================
# 用法:
#   var width = GameConfig.DEFAULT_GRID_WIDTH
#   GameConfig.FACTIONS["zerg"]   →  阵营资源路径
#
# 配置:
#   项目设置 → Autoload → Path: res://scripts/core/game_config.gd
#   Node Name: GameConfig
# ============================================================
extends Node

# ──────────────────────────────────────────
# 玩家与网格
# ──────────────────────────────────────────
const MAX_PLAYERS: int = 4
const DEFAULT_GRID_WIDTH: int = 20
const DEFAULT_GRID_HEIGHT: int = 20
const BASE_STARTING_ENERGY: int = 5
const DEFAULT_ACTIONS_PER_TURN: int = 2

# ──────────────────────────────────────────
# 阵营资源映射
# ──────────────────────────────────────────
const FACTIONS: Dictionary = {
	"zerg": "res://scripts/factions/faction_zerg.gd",
	"terran": "res://scripts/factions/faction_terran.gd",
	"protoss": "res://scripts/factions/faction_protoss.gd"
}

# ──────────────────────────────────────────
# PVE - BOSS 难度配置
# ──────────────────────────────────────────
const BOSS_STATS: Dictionary = {
	"default": {
		"hp": 5000,
		"attack": 150,
		"attack_interval": 3  # 每N回合攻击一次
	},
	"hard": {
		"hp": 10000,
		"attack": 250,
		"attack_interval": 2
	}
}

# ──────────────────────────────────────────
# 回合 / 资源相关
# ──────────────────────────────────────────
const MAX_ENERGY_PER_TURN: int = 10
const ENERGY_REGEN_PER_TURN: int = 3


func _ready() -> void:
	print("[GameConfig] ✅ 游戏配置已加载")
	print("  网格大小: ", DEFAULT_GRID_WIDTH, " × ", DEFAULT_GRID_HEIGHT)
	print("  阵营数量: ", FACTIONS.size())
	print("  BOSS 难度档位: ", BOSS_STATS.keys())
