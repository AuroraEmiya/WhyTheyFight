# ============================================================
# test_map_data.gd — MapData & MovementRule 基础验证
# ============================================================
# 测试范围:
#   1. MapData 创建与边界查询
#   2. 地形层设置与读取
#   3. 单位/建筑/资源/效果层基本操作
#   4. MovementRule 通行判断（Road / Water / Obstacle）
#   5. 建筑/单位占用阻挡
#   6. 失败判断不修改状态
# ============================================================
extends Node2D


# ──────────────────────────────────────────
# 测试状态
# ──────────────────────────────────────────
var _tests_passed: int = 0
var _tests_failed: int = 0
var _failures: Array[String] = []


# ============================================================
# 入口
# ============================================================
func _ready() -> void:
	print("=".repeat(60))
	print("  MapData & MovementRule 基础验证")
	print("=".repeat(60))

	_test_map_creation()
	_test_boundary_check()
	_test_terrain_layer()
	_test_structure_layer()
	_test_unit_layer()
	_test_resource_layer()
	_test_effect_layer()
	_test_passability_road()
	_test_passability_water()
	_test_passability_obstacle()
	_test_passability_structure_blocking()
	_test_passability_unit_blocking()
	_test_passability_no_state_modification()
	_test_100x100_map()

	_print_summary()


# ============================================================
# 1. MapData 创建
# ============================================================
func _test_map_creation() -> void:
	print("\n── 测试 1: MapData 创建 ──")

	var md := MapData.new(100, 100)
	_expect(md != null, "MapData 实例创建成功")
	_expect(md.width == 100, "width == 100")
	_expect(md.height == 100, "height == 100")
	_expect(md.terrain_layer.is_empty(), "地形层初始为空")
	_expect(md.structure_layer.is_empty(), "建筑层初始为空")
	_expect(md.unit_layer.is_empty(), "单位层初始为空")
	_expect(md.resource_layer.is_empty(), "资源层初始为空")
	_expect(md.effect_layer.is_empty(), "效果层初始为空")


# ============================================================
# 2. 边界查询
# ============================================================
func _test_boundary_check() -> void:
	print("\n── 测试 2: 边界查询 is_inside ──")

	var md := MapData.new(100, 100)

	_expect(md.is_inside(Vector2i(0, 0)), "(0, 0) 在界内")
	_expect(md.is_inside(Vector2i(99, 99)), "(99, 99) 在界内")
	_expect(md.is_inside(Vector2i(50, 50)), "(50, 50) 在界内")
	_expect(md.is_inside(Vector2i(0, 99)), "(0, 99) 在界内")
	_expect(md.is_inside(Vector2i(99, 0)), "(99, 0) 在界内")

	_expect(not md.is_inside(Vector2i(-1, 0)), "(-1, 0) 越界")
	_expect(not md.is_inside(Vector2i(0, -1)), "(0, -1) 越界")
	_expect(not md.is_inside(Vector2i(100, 0)), "(100, 0) 越界")
	_expect(not md.is_inside(Vector2i(0, 100)), "(0, 100) 越界")
	_expect(not md.is_inside(Vector2i(-1, -1)), "(-1, -1) 越界")


# ============================================================
# 3. 地形层
# ============================================================
func _test_terrain_layer() -> void:
	print("\n── 测试 3: 地形层设置与读取 ──")

	var md := MapData.new(100, 100)

	# 默认地形为 ROAD
	_expect(md.get_terrain(Vector2i(10, 10)) == MapData.TerrainType.ROAD,
		"未设置时默认地形为 ROAD")

	# 设置水域
	md.set_terrain(Vector2i(5, 5), MapData.TerrainType.WATER)
	_expect(md.get_terrain(Vector2i(5, 5)) == MapData.TerrainType.WATER,
		"设置 (5,5) 为 WATER → 读取正确")

	# 设置障碍
	md.set_terrain(Vector2i(8, 8), MapData.TerrainType.OBSTACLE)
	_expect(md.get_terrain(Vector2i(8, 8)) == MapData.TerrainType.OBSTACLE,
		"设置 (8,8) 为 OBSTACLE → 读取正确")

	# 覆盖设置
	md.set_terrain(Vector2i(5, 5), MapData.TerrainType.ROAD)
	_expect(md.get_terrain(Vector2i(5, 5)) == MapData.TerrainType.ROAD,
		"覆盖设置 (5,5) 为 ROAD → 读取正确")

	# 相邻格子不受影响
	_expect(md.get_terrain(Vector2i(5, 6)) == MapData.TerrainType.ROAD,
		"相邻格子 (5,6) 仍为默认 ROAD")


# ============================================================
# 4. 建筑层
# ============================================================
func _test_structure_layer() -> void:
	print("\n── 测试 4: 建筑层 ──")

	var md := MapData.new(100, 100)

	# 初始无建筑
	_expect(not md.has_structure(Vector2i(10, 10)), "初始 (10,10) 无建筑")
	_expect(md.get_structure_id(Vector2i(10, 10)) == -1, "无建筑时 get_structure_id → -1")

	# 放置建筑
	md.place_structure(Vector2i(10, 10), 42)
	_expect(md.has_structure(Vector2i(10, 10)), "放置建筑后 has_structure → true")
	_expect(md.get_structure_id(Vector2i(10, 10)) == 42, "get_structure_id → 42")

	# 另一格子不受影响
	_expect(not md.has_structure(Vector2i(11, 10)), "相邻格 (11,10) 无建筑")

	# 移除建筑
	md.remove_structure(Vector2i(10, 10))
	_expect(not md.has_structure(Vector2i(10, 10)), "移除后 has_structure → false")
	_expect(md.get_structure_id(Vector2i(10, 10)) == -1, "移除后 get_structure_id → -1")


# ============================================================
# 5. 单位层
# ============================================================
func _test_unit_layer() -> void:
	print("\n── 测试 5: 单位层 ──")

	var md := MapData.new(100, 100)

	# 初始无单位
	_expect(not md.has_unit(Vector2i(20, 20)), "初始 (20,20) 无单位")
	_expect(md.get_unit_id(Vector2i(20, 20)) == -1, "无单位时 get_unit_id → -1")

	# 放置单位
	md.place_unit(Vector2i(20, 20), 7)
	_expect(md.has_unit(Vector2i(20, 20)), "放置单位后 has_unit → true")
	_expect(md.get_unit_id(Vector2i(20, 20)) == 7, "get_unit_id → 7")

	# 移除单位
	md.remove_unit(Vector2i(20, 20))
	_expect(not md.has_unit(Vector2i(20, 20)), "移除后 has_unit → false")


# ============================================================
# 6. 资源层
# ============================================================
func _test_resource_layer() -> void:
	print("\n── 测试 6: 资源层 ──")

	var md := MapData.new(100, 100)
	_expect(not md.has_resource(Vector2i(30, 30)), "初始 (30,30) 无资源")
	_expect(md.get_resource_id(Vector2i(30, 30)) == -1, "无资源时 get_resource_id → -1")


# ============================================================
# 7. 效果层
# ============================================================
func _test_effect_layer() -> void:
	print("\n── 测试 7: 效果层 ──")

	var md := MapData.new(100, 100)

	_expect(not md.has_effect(Vector2i(15, 15)), "初始 (15,15) 无效果")
	var empty := md.get_effect_ids(Vector2i(15, 15))
	_expect(empty.is_empty(), "无效果时 get_effect_ids → 空数组")

	md.add_effect(Vector2i(15, 15), 100)
	md.add_effect(Vector2i(15, 15), 200)
	_expect(md.has_effect(Vector2i(15, 15)), "添加效果后 has_effect → true")
	var ids := md.get_effect_ids(Vector2i(15, 15))
	_expect(ids.size() == 2, "效果数量 == 2")
	_expect(ids.has(100) and ids.has(200), "包含效果 100 和 200")

	md.clear_effects(Vector2i(15, 15))
	_expect(not md.has_effect(Vector2i(15, 15)), "清空后 has_effect → false")


# ============================================================
# 8. 通行判断 — Road
# ============================================================
func _test_passability_road() -> void:
	print("\n── 测试 8: 通行判断 — Road ──")

	var md := MapData.new(100, 100)
	var rule := MovementRule.new()

	# 默认道路单位
	var unit := CombatEntityModel.new()
	unit.entity_id = 1
	unit.can_move = true
	unit.can_swim = false

	# Road 默认可通行
	md.set_terrain(Vector2i(10, 10), MapData.TerrainType.ROAD)
	_expect(rule.can_unit_enter(unit, Vector2i(10, 10), md),
		"Road: 普通单位可通行")

	var result := rule.check_can_enter(unit, Vector2i(10, 10), md)
	_expect(result.is_valid, "Road: check_can_enter → OK")


# ============================================================
# 9. 通行判断 — Water
# ============================================================
func _test_passability_water() -> void:
	print("\n── 测试 9: 通行判断 — Water ──")

	var md := MapData.new(100, 100)
	var rule := MovementRule.new()
	md.set_terrain(Vector2i(5, 5), MapData.TerrainType.WATER)

	# 普通单位不可通行水域
	var land_unit := CombatEntityModel.new()
	land_unit.entity_id = 1
	land_unit.can_swim = false
	_expect(not rule.can_unit_enter(land_unit, Vector2i(5, 5), md),
		"Water: 无 can_swim 的单位不可通行")
	var r1 := rule.check_can_enter(land_unit, Vector2i(5, 5), md)
	_expect(not r1.is_valid, "Water: check_can_enter → FAIL (无游泳能力)")

	# can_swim 单位可通行水域
	var swim_unit := CombatEntityModel.new()
	swim_unit.entity_id = 2
	swim_unit.can_swim = true
	_expect(rule.can_unit_enter(swim_unit, Vector2i(5, 5), md),
		"Water: can_swim 单位可通行")
	var r2 := rule.check_can_enter(swim_unit, Vector2i(5, 5), md)
	_expect(r2.is_valid, "Water: check_can_enter → OK (有游泳能力)")


# ============================================================
# 10. 通行判断 — Obstacle
# ============================================================
func _test_passability_obstacle() -> void:
	print("\n── 测试 10: 通行判断 — Obstacle ──")

	var md := MapData.new(100, 100)
	var rule := MovementRule.new()
	md.set_terrain(Vector2i(3, 3), MapData.TerrainType.OBSTACLE)

	# 任何单位都不能通行障碍
	var unit := CombatEntityModel.new()
	unit.entity_id = 1
	unit.can_swim = true  # 即使是游泳单位也不能通过障碍

	_expect(not rule.can_unit_enter(unit, Vector2i(3, 3), md),
		"Obstacle: 即使 can_swim 也不可通行")
	var result := rule.check_can_enter(unit, Vector2i(3, 3), md)
	_expect(not result.is_valid, "Obstacle: check_can_enter → FAIL")


# ============================================================
# 11. 建筑阻挡
# ============================================================
func _test_passability_structure_blocking() -> void:
	print("\n── 测试 11: 通行判断 — 建筑阻挡 ──")

	var md := MapData.new(100, 100)
	var rule := MovementRule.new()
	var unit := CombatEntityModel.new()
	unit.entity_id = 1
	unit.can_move = true

	# 在 ROAD 上放置建筑 → 不可通行
	md.set_terrain(Vector2i(7, 7), MapData.TerrainType.ROAD)
	_expect(rule.can_unit_enter(unit, Vector2i(7, 7), md),
		"无建筑时 (7,7) 可通行")

	md.place_structure(Vector2i(7, 7), 99)
	_expect(not rule.can_unit_enter(unit, Vector2i(7, 7), md),
		"放置建筑后 (7,7) 不可通行")
	var r1 := rule.check_can_enter(unit, Vector2i(7, 7), md)
	_expect(not r1.is_valid, "建筑阻挡: check_can_enter → FAIL")
	_expect("建筑" in r1.reason, "失败原因包含'建筑'")

	# 移除建筑后恢复可通行
	md.remove_structure(Vector2i(7, 7))
	_expect(rule.can_unit_enter(unit, Vector2i(7, 7), md),
		"移除建筑后 (7,7) 恢复可通行")


# ============================================================
# 12. 单位阻挡
# ============================================================
func _test_passability_unit_blocking() -> void:
	print("\n── 测试 12: 通行判断 — 单位阻挡 ──")

	var md := MapData.new(100, 100)
	var rule := MovementRule.new()
	var unit := CombatEntityModel.new()
	unit.entity_id = 1
	unit.can_move = true

	md.set_terrain(Vector2i(4, 4), MapData.TerrainType.ROAD)
	md.place_unit(Vector2i(4, 4), 999)

	_expect(not rule.can_unit_enter(unit, Vector2i(4, 4), md),
		"有单位占用的格子不可通行")
	var result := rule.check_can_enter(unit, Vector2i(4, 4), md)
	_expect(not result.is_valid, "单位阻挡: check_can_enter → FAIL")
	_expect("单位" in result.reason, "失败原因包含'单位'")

	md.remove_unit(Vector2i(4, 4))
	_expect(rule.can_unit_enter(unit, Vector2i(4, 4), md),
		"移除单位后恢复可通行")


# ============================================================
# 13. 失败判断不修改状态
# ============================================================
func _test_passability_no_state_modification() -> void:
	print("\n── 测试 13: 失败判断不修改状态 ──")

	var md := MapData.new(100, 100)
	var rule := MovementRule.new()
	var unit := CombatEntityModel.new()
	unit.entity_id = 1
	unit.can_swim = false

	# 设置初始状态
	md.set_terrain(Vector2i(1, 1), MapData.TerrainType.WATER)
	md.place_structure(Vector2i(2, 2), 10)
	md.place_unit(Vector2i(3, 3), 20)

	# 记录检查前状态
	var terrain_before := md.get_terrain(Vector2i(1, 1))
	var struct_before := md.has_structure(Vector2i(2, 2))
	var unit_before := md.has_unit(Vector2i(3, 3))
	var unit_cell_before := unit.cell
	var unit_hp_before := unit.hp
	var unit_can_swim_before := unit.can_swim

	# 执行多次失败检查
	rule.check_can_enter(unit, Vector2i(-1, -1), md)  # 越界
	rule.check_can_enter(unit, Vector2i(1, 1), md)    # 水域不可通行
	rule.check_can_enter(unit, Vector2i(2, 2), md)    # 建筑阻挡
	rule.check_can_enter(unit, Vector2i(3, 3), md)    # 单位阻挡

	# 验证状态不变
	_expect(md.get_terrain(Vector2i(1, 1)) == terrain_before, "地形层未被修改")
	_expect(md.has_structure(Vector2i(2, 2)) == struct_before, "建筑层未被修改")
	_expect(md.has_unit(Vector2i(3, 3)) == unit_before, "单位层未被修改")
	_expect(unit.cell == unit_cell_before, "单位坐标未被修改")
	_expect(unit.hp == unit_hp_before, "单位 HP 未被修改")
	_expect(unit.can_swim == unit_can_swim_before, "单位 can_swim 未被修改")


# ============================================================
# 14. 100×100 地图
# ============================================================
func _test_100x100_map() -> void:
	print("\n── 测试 14: 100×100 地图 ──")

	var md := MapData.new(100, 100)
	_expect(md.width == 100 and md.height == 100, "尺寸 100×100")

	# 验证所有边界
	_expect(md.is_inside(Vector2i(0, 0)), "100×100: (0,0) 在界内")
	_expect(md.is_inside(Vector2i(99, 99)), "100×100: (99,99) 在界内")
	_expect(not md.is_inside(Vector2i(100, 100)), "100×100: (100,100) 越界")

	# 在100×100地图上设置地形
	md.set_terrain(Vector2i(50, 50), MapData.TerrainType.WATER)
	md.set_terrain(Vector2i(80, 80), MapData.TerrainType.OBSTACLE)

	var rule := MovementRule.new()
	var land_unit := CombatEntityModel.new()
	land_unit.entity_id = 1
	land_unit.can_swim = false
	var swim_unit := CombatEntityModel.new()
	swim_unit.entity_id = 2
	swim_unit.can_swim = true

	# 验证100×100中的通行判断
	_expect(rule.can_unit_enter(land_unit, Vector2i(50, 50), md) == false, "100×100: 普通单位不能进入水域 (50,50)")
	_expect(rule.can_unit_enter(swim_unit, Vector2i(50, 50), md) == true, "100×100: 游泳单位可以进入水域 (50,50)")
	_expect(rule.can_unit_enter(land_unit, Vector2i(80, 80), md) == false, "100×100: 普通单位不能进入障碍 (80,80)")
	_expect(rule.can_unit_enter(swim_unit, Vector2i(80, 80), md) == false, "100×100: 游泳单位也不能进入障碍 (80,80)")
	_expect(rule.can_unit_enter(land_unit, Vector2i(30, 30), md) == true, "100×100: 默认 ROAD 可通行 (30,30)")


# ============================================================
# 辅助
# ============================================================
func _expect(condition: bool, description: String) -> void:
	if condition:
		_tests_passed += 1
		print("  ✅ PASS: %s" % description)
	else:
		_tests_failed += 1
		printerr("  ❌ FAIL: %s" % description)
		_failures.append(description)


func _print_summary() -> void:
	var total := _tests_passed + _tests_failed
	print("\n" + "=".repeat(60))
	print("  MapData & MovementRule 验证完成: %d/%d 通过" % [_tests_passed, total])
	if _tests_failed > 0:
		printerr("  %d 项失败:" % _tests_failed)
		for line in _failures:
			printerr("    - %s" % line)
	else:
		print("  🎉 全部通过！")
	print("=".repeat(60))
