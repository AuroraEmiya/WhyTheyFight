# ============================================================
# MapData - 分层地图数据模型
# ============================================================
# 类型: RefCounted（纯数据，不依赖场景节点）
#
# 地图采用分层结构，每层独立管理：
#   Terrain Layer    地形层 — 格子的地形类型
#   Structure Layer  建筑层 — 建筑/不可移动结构
#   Unit Layer       单位层 — 可移动单位
#   Resource Layer   资源层 — 资源点/可交互资源对象
#   Effect Layer     效果层 — 污染/祝福/诅咒/火焰等
#
# 一个格子可以同时具有多层信息。
#
# 设计依据: docs/GAME_DESIGN_AGENT.md §2, §7.2
# ============================================================
class_name MapData
extends RefCounted


# ──────────────────────────────────────────
# 地形枚举
# ──────────────────────────────────────────
enum TerrainType {
	ROAD = 0,     # 道路 — 所有可移动单位默认可以通行
	WATER = 1,    # 水域 — 仅 can_swim 单位可以通行
	OBSTACLE = 2, # 障碍 — 默认不可通行、不可建造
}


# ──────────────────────────────────────────
# 地图尺寸
# ──────────────────────────────────────────
var width: int = 0
var height: int = 0


# ──────────────────────────────────────────
# 分层数据
# ──────────────────────────────────────────
## 地形层: Dictionary[Vector2i, TerrainType]
## 未设置的格子默认视为 ROAD
var terrain_layer: Dictionary = {}

## 建筑层: Dictionary[Vector2i, int]
## key = 格子坐标, value = structure_id
## structure_id > 0 表示该格被建筑占用
var structure_layer: Dictionary = {}

## 单位层: Dictionary[Vector2i, int]
## key = 格子坐标, value = unit_id
## unit_id > 0 表示该格被单位占用
var unit_layer: Dictionary = {}

## 资源层: Dictionary[Vector2i, int]
## key = 格子坐标, value = resource_id
var resource_layer: Dictionary = {}

## 效果层: Dictionary[Vector2i, Array]
## key = 格子坐标, value = Array[int] (effect_ids)
var effect_layer: Dictionary = {}


# ──────────────────────────────────────────
# 初始化
# ──────────────────────────────────────────

## 创建指定尺寸的地图数据对象
## @param w: 地图宽度（格子数）
## @param h: 地图高度（格子数）
func _init(w: int = 0, h: int = 0) -> void:
	width = w
	height = h


# ──────────────────────────────────────────
# 边界查询
# ──────────────────────────────────────────

## 判断坐标是否在地图范围内
func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height


# ──────────────────────────────────────────
# 地形层
# ──────────────────────────────────────────

## 获取指定格子的地形类型
## 未设置的格子默认返回 ROAD
func get_terrain(cell: Vector2i) -> TerrainType:
	return terrain_layer.get(cell, TerrainType.ROAD)


## 设置指定格子的地形类型
func set_terrain(cell: Vector2i, terrain: TerrainType) -> void:
	terrain_layer[cell] = terrain


# ──────────────────────────────────────────
# 建筑层
# ──────────────────────────────────────────

## 判断指定格子是否有建筑
func has_structure(cell: Vector2i) -> bool:
	return structure_layer.has(cell)


## 获取指定格子的建筑 ID
## @return int: structure_id，若无建筑返回 -1
func get_structure_id(cell: Vector2i) -> int:
	return structure_layer.get(cell, -1)


## 在指定格子放置建筑
func place_structure(cell: Vector2i, structure_id: int) -> void:
	structure_layer[cell] = structure_id


## 移除指定格子的建筑
func remove_structure(cell: Vector2i) -> void:
	structure_layer.erase(cell)


# ──────────────────────────────────────────
# 单位层
# ──────────────────────────────────────────

## 判断指定格子是否有单位
func has_unit(cell: Vector2i) -> bool:
	return unit_layer.has(cell)


## 获取指定格子的单位 ID
## @return int: unit_id，若无单位返回 -1
func get_unit_id(cell: Vector2i) -> int:
	return unit_layer.get(cell, -1)


## 在指定格子放置单位
func place_unit(cell: Vector2i, unit_id: int) -> void:
	unit_layer[cell] = unit_id


## 移除指定格子的单位
func remove_unit(cell: Vector2i) -> void:
	unit_layer.erase(cell)


# ──────────────────────────────────────────
# 资源层
# ──────────────────────────────────────────

## 判断指定格子是否有资源
func has_resource(cell: Vector2i) -> bool:
	return resource_layer.has(cell)


## 获取指定格子的资源 ID
func get_resource_id(cell: Vector2i) -> int:
	return resource_layer.get(cell, -1)


# ──────────────────────────────────────────
# 效果层
# ──────────────────────────────────────────

## 判断指定格子是否有活跃效果
func has_effect(cell: Vector2i) -> bool:
	return effect_layer.has(cell) and not effect_layer[cell].is_empty()


## 获取指定格子的效果 ID 列表
func get_effect_ids(cell: Vector2i) -> Array:
	return effect_layer.get(cell, [])


## 向指定格子添加效果
func add_effect(cell: Vector2i, effect_id: int) -> void:
	if not effect_layer.has(cell):
		effect_layer[cell] = []
	effect_layer[cell].append(effect_id)


## 清空指定格子的所有效果
func clear_effects(cell: Vector2i) -> void:
	effect_layer.erase(cell)


# ──────────────────────────────────────────
# 调试
# ──────────────────────────────────────────

func _to_string() -> String:
	return "MapData(%d×%d, terrain_keys=%d, structures=%d, units=%d, resources=%d, effects=%d)" % [
		width, height,
		terrain_layer.size(),
		structure_layer.size(),
		unit_layer.size(),
		resource_layer.size(),
		effect_layer.size()
	]
