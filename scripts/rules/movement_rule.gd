# ============================================================
# MovementRule - 移动合法性规则（纯逻辑，不操作场景节点）
# ============================================================
# 类型: RefCounted（纯规则计算）
#
# 负责判断单位是否可以进入目标格子。
# 按分层顺序检查: 边界 → 地形 → 建筑 → 单位 → 效果
#
# 设计依据: docs/GAME_DESIGN_AGENT.md §10
# 通行规则: docs/GAME_DESIGN_DEVELOPER.md §5.7
# ============================================================
class_name MovementRule
extends RefCounted


# ──────────────────────────────────────────
# 公开方法: 简单布尔检查
# ──────────────────────────────────────────

## 判断单位是否能进入目标格（布尔返回值）
## @param unit: 尝试移动的单位
## @param cell: 目标格坐标
## @param map_data: 地图数据（分层结构）
## @return bool: true 表示可通行
func can_unit_enter(unit: CombatEntityModel, cell: Vector2i, map_data: MapData) -> bool:
	var result := check_can_enter(unit, cell, map_data)
	return result.is_valid


# ──────────────────────────────────────────
# 公开方法: 结构化检查
# ──────────────────────────────────────────

## 判断单位是否能进入目标格（结构化返回值）
## 此方法不修改任何游戏状态。
##
## 检查顺序（按设计文档 §10 要求）:
##   1. 目标格是否在地图范围内？
##   2. 地形是否允许该单位进入？
##   3. 是否存在阻挡建筑？
##   4. 是否存在阻挡单位？
##   5. 是否存在阻挡效果？
##   6. 返回最终可通行结果。
##
## @param unit: 尝试移动的单位
## @param cell: 目标格坐标
## @param map_data: 地图数据（分层结构）
## @return ActionCheckResult
func check_can_enter(unit: CombatEntityModel, cell: Vector2i, map_data: MapData) -> ActionCheckResult:
	# ── 1. 边界检查 ──
	if not map_data.is_inside(cell):
		return ActionCheckResult.fail("目标格 (%d, %d) 超出地图范围" % [cell.x, cell.y])

	# ── 2. 地形通行性 ──
	var terrain: MapData.TerrainType = map_data.get_terrain(cell)
	match terrain:
		MapData.TerrainType.ROAD:
			pass  # 所有可移动单位默认可以通行
		MapData.TerrainType.WATER:
			if not unit.can_swim:
				return ActionCheckResult.fail("目标格 (%d, %d) 为水域，单位不具备 can_swim 能力" % [cell.x, cell.y])
		MapData.TerrainType.OBSTACLE:
			return ActionCheckResult.fail("目标格 (%d, %d) 为障碍，不可通行" % [cell.x, cell.y])
		_:
			return ActionCheckResult.fail("目标格 (%d, %d) 地形类型未知" % [cell.x, cell.y])

	# ── 3. 建筑阻挡 ──
	if map_data.has_structure(cell):
		# 设计规则: 有建筑的格子默认不可通行
		# 临时假设: 所有建筑默认阻挡移动 (参见 docs/OPEN_QUESTIONS.md §5 Q5)
		return ActionCheckResult.fail("目标格 (%d, %d) 被建筑占用" % [cell.x, cell.y])

	# ── 4. 单位阻挡 ──
	if map_data.has_unit(cell):
		return ActionCheckResult.fail("目标格 (%d, %d) 被其他单位占用" % [cell.x, cell.y])

	# ── 5. 效果阻挡 ──
	# 当前暂不实现具体阻挡效果（如火焰、力场等）
	# 预留检查点供后续扩展
	if map_data.has_effect(cell):
		# 临时: 所有效果视为非阻挡
		# TODO: 当效果系统明确后，在此处检查是否存在阻挡类效果
		pass

	# ── 6. 通过所有检查 ──
	return ActionCheckResult.ok()
