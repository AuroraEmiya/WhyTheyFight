# ============================================================
# GridCell - 网格单元格数据
# ============================================================
# 类型: Resource（轻量数据对象，便于序列化和编辑器查看）
#
# 每个 GridCell 描述网格中一个格子的：
#   - 地形类型（影响移动消耗）
#   - 占用状态（是否有单位/建筑在此格）
#   - 坐标位置
# ============================================================
class_name GridCell
extends Resource


# ──────────────────────────────────────────
# 地形枚举
# ──────────────────────────────────────────
enum Terrain {
	PLAIN = 0,    # 平原 — 移动消耗 1.0
	FOREST = 1,   # 森林 — 移动消耗 1.5，提供掩体
	MOUNTAIN = 2, # 山地 — 移动消耗 2.0，远程单位射程+1
	WATER = 3,    # 水域 — 地面单位不可通行
	WALL = 4,     # 墙壁 — 不可通行
}


# ──────────────────────────────────────────
# 属性
# ──────────────────────────────────────────

## 格子在网格中的坐标
@export var grid_position: Vector2i = Vector2i.ZERO

## 地形类型
@export var terrain: Terrain = Terrain.PLAIN

## 是否被单位/建筑占用
@export var is_occupied: bool = false

## 占用者的唯一ID（0 表示无占用者）
@export var occupant_id: int = 0


# ──────────────────────────────────────────
# 计算属性
# ──────────────────────────────────────────

## 获取该地形的移动消耗系数
func get_movement_cost() -> float:
	match terrain:
		Terrain.PLAIN:
			return 1.0
		Terrain.FOREST:
			return 1.5
		Terrain.MOUNTAIN:
			return 2.0
		Terrain.WATER:
			return INF   # 不可通行
		Terrain.WALL:
			return INF
		_:
			return 1.0


## 该格子是否可通行（地面单位）
func is_walkable() -> bool:
	return terrain != Terrain.WATER and terrain != Terrain.WALL


## 该格子是否提供掩体
func provides_cover() -> bool:
	return terrain == Terrain.FOREST


## 该格子是否为高地（远程优势）
func is_high_ground() -> bool:
	return terrain == Terrain.MOUNTAIN


# ──────────────────────────────────────────
# 公开方法
# ──────────────────────────────────────────

## 占用此格子
## @param id: 占用者的唯一ID
func occupy(id: int) -> void:
	is_occupied = true
	occupant_id = id


## 释放此格子（命名 release 避免与 RefCounted.free() 冲突）
func release() -> void:
	is_occupied = false
	occupant_id = 0


## 重置为默认状态
func reset() -> void:
	grid_position = Vector2i.ZERO
	terrain = Terrain.PLAIN
	is_occupied = false
	occupant_id = 0


# ──────────────────────────────────────────
# 序列化
# ──────────────────────────────────────────

func _to_string() -> String:
	return "GridCell(%s, %s, occupied=%s)" % [
		grid_position,
		Terrain.keys()[terrain],
		is_occupied
	]
