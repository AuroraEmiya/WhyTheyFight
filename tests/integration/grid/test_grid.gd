# ============================================================
# test_grid.gd — 网格系统集成测试
# ============================================================
# 测试范围:
#   1. GridCell  — 地形、通行性、移动消耗
#   2. GridManager — 初始化、格子访问
#   3. 占用系统  — occupy / free / 冲突检测
#   4. 相邻查询  — 4方向 / 8方向 / 边界
#   5. A* 寻路   — 直线 / 绕障 / 不可达 / 地形消耗
# ============================================================
extends Node2D


# ──────────────────────────────────────────
# 测试状态
# ──────────────────────────────────────────
var _tests_passed: int = 0
var _tests_failed: int = 0
var _failures: Array[String] = []

	# ── 创建 GridManager ──
var _gm = preload("res://scripts/grid/grid_manager.gd").new()


# ============================================================
# 入口
# ============================================================
func _ready() -> void:
	print("=".repeat(60))
	print("  网格系统集成测试")
	print("=".repeat(60))
	
	# ── 创建 GridManager ──
	_gm.name = "GridManager"
	add_child(_gm)
	await get_tree().process_frame  # GridManager 实例


	# ── 初始化网格（使用非默认尺寸以便验证参数传递） ──
	_gm.initialize(10, 10)   # 10x10 够用，且方便手动验证
	await get_tree().process_frame

	# ── 运行测试 ──
	_test_grid_cell()
	_test_initialization()
	_test_occupancy()
	_test_adjacency()
	_test_pathfinding_straight()
	_test_pathfinding_obstacle()
	_test_pathfinding_unreachable()
	_test_pathfinding_edge_cases()

	_print_summary()


# ============================================================
# 1. GridCell 基础
# ============================================================
func _test_grid_cell() -> void:
	print("\n── 测试 1: GridCell 基础 ──")

	var cell := GridCell.new()
	cell.grid_position = Vector2i(3, 5)
	cell.terrain = GridCell.Terrain.FOREST

	_expect(cell.grid_position == Vector2i(3, 5), "grid_position 设置正确")
	_expect(cell.terrain == GridCell.Terrain.FOREST, "terrain 设置正确")
	_expect(not cell.is_occupied, "默认未占用")
	_expect(cell.occupant_id == 0, "默认 occupant_id == 0")

	# 地形通行性
	var plain_cell := GridCell.new()
	plain_cell.terrain = GridCell.Terrain.PLAIN
	_expect(plain_cell.is_walkable(), "PLAIN 可通行")
	_expect(plain_cell.get_movement_cost() == 1.0, "PLAIN 移动消耗 1.0")

	var water_cell := GridCell.new()
	water_cell.terrain = GridCell.Terrain.WATER
	_expect(not water_cell.is_walkable(), "WATER 不可通行")
	_expect(water_cell.get_movement_cost() >= 999.0, "WATER 移动消耗 INF")

	var wall_cell := GridCell.new()
	wall_cell.terrain = GridCell.Terrain.WALL
	_expect(not wall_cell.is_walkable(), "WALL 不可通行")

	# 占用 / 释放
	cell.occupy(42)
	_expect(cell.is_occupied, "occupy(42) → 已占用")
	_expect(cell.occupant_id == 42, "occupant_id == 42")

	cell.release()
	_expect(not cell.is_occupied, "free() → 未占用")
	_expect(cell.occupant_id == 0, "free() 后 occupant_id == 0")

	# 掩体 / 高地
	var forest := GridCell.new()
	forest.terrain = GridCell.Terrain.FOREST
	_expect(forest.provides_cover(), "FOREST 提供掩体")

	var mountain := GridCell.new()
	mountain.terrain = GridCell.Terrain.MOUNTAIN
	_expect(mountain.is_high_ground(), "MOUNTAIN 是高地")
	_expect(mountain.get_movement_cost() == 2.0, "MOUNTAIN 移动消耗 2.0")


# ============================================================
# 2. 网格初始化
# ============================================================
func _test_initialization() -> void:
	print("\n── 测试 2: 网格初始化 ──")

	_expect(_gm.grid_width == 10, "grid_width == 10")
	_expect(_gm.grid_height == 10, "grid_height == 10")
	_expect(_gm.is_within_bounds(Vector2i(0, 0)), "(0,0) 在界内")
	_expect(_gm.is_within_bounds(Vector2i(9, 9)), "(9,9) 在界内")
	_expect(not _gm.is_within_bounds(Vector2i(-1, 0)), "(-1,0) 越界")
	_expect(not _gm.is_within_bounds(Vector2i(0, 10)), "(0,10) 越界")
	_expect(not _gm.is_within_bounds(Vector2i(10, 0)), "(10,0) 越界")

	# 每个格子都被正确创建
	var all_plain := true
	var all_unoccupied := true
	for y in range(10):
		for x in range(10):
			var cell : GridCell = _gm.get_cell(Vector2i(x, y))
			if cell == null:
				all_plain = false
				break
			if cell.terrain != GridCell.Terrain.PLAIN:
				all_plain = false
			if cell.is_occupied:
				all_unoccupied = false
	_expect(all_plain, "所有格子初始地形为 PLAIN")
	_expect(all_unoccupied, "所有格子初始未占用")

	# get_cell 越界返回 null
	_expect(_gm.get_cell(Vector2i(99, 99)) == null, "越界 get_cell 返回 null")


# ============================================================
# 3. 占用系统
# ============================================================
func _test_occupancy() -> void:
	print("\n── 测试 3: 占用系统 ──")

	var pos := Vector2i(4, 4)

	# 初始未占用
	_expect(not _gm.is_cell_occupied(pos), "初始 (4,4) 未占用")
	_expect(_gm.is_cell_walkable(pos), "初始 (4,4) 可通行")

	# 占用成功
	var ok := _gm.occupy_cell(pos, 100)
	_expect(ok != null, "occupy_cell(4,4, 100) 成功")
	_expect(_gm.is_cell_occupied(pos), "占用后 is_cell_occupied → true")
	_expect(not _gm.is_cell_walkable(pos), "占用后 is_cell_walkable → false")
	var cell : GridCell = _gm.get_cell(pos)
	_expect(cell.occupant_id == 100, "occupant_id == 100")

	# 不可重复占用
	var ok2 := _gm.occupy_cell(pos, 200)
	_expect(not ok2, "重复占用 (4,4) 失败")
	_expect(cell.occupant_id == 100, "occupant_id 仍为 100")

	# 释放后恢复
	_gm.free_cell(pos)
	_expect(not _gm.is_cell_occupied(pos), "free 后未占用")
	_expect(_gm.is_cell_walkable(pos), "free 后可通行")

	# 释放后可重新占用
	var ok3 := _gm.occupy_cell(pos, 300)
	_expect(ok3 != null, "释放后重新占用成功")
	_expect(_gm.get_cell(pos).occupant_id == 300, "重新占用 occupant_id == 300")
	_gm.free_cell(pos)  # 清理

	# 越界 occupy 失败
	_expect(not _gm.occupy_cell(Vector2i(99, 99), 1), "越界 occupy 返回 false")
	_expect(_gm.is_cell_occupied(Vector2i(99, 99)), "越界 is_cell_occupied → true（视为不可用）")

	# 水域不可通行（即使未占用）
	var water_pos := Vector2i(7, 7)
	_gm.set_cell_terrain(water_pos, GridCell.Terrain.WATER)
	_expect(not _gm.is_cell_walkable(water_pos), "水域不可通行")


# ============================================================
# 4. 相邻查询
# ============================================================
func _test_adjacency() -> void:
	print("\n── 测试 4: 相邻查询 ──")

	# ── 4a: 中心格（4方向）──
	var adj4 := _gm.get_adjacent_positions(Vector2i(5, 5), false)
	_expect(adj4.size() == 4, "中心格 4方向邻格 = 4 个")
	_expect(Vector2i(5, 4) in adj4, "包含 (5,4) 上")
	_expect(Vector2i(6, 5) in adj4, "包含 (6,5) 右")
	_expect(Vector2i(5, 6) in adj4, "包含 (5,6) 下")
	_expect(Vector2i(4, 5) in adj4, "包含 (4,5) 左")

	# ── 4b: 中心格（8方向）──
	var adj8 := _gm.get_adjacent_positions(Vector2i(5, 5), true)
	_expect(adj8.size() == 8, "中心格 8方向邻格 = 8 个")
	_expect(Vector2i(4, 4) in adj8, "包含 (4,4) 左上")
	_expect(Vector2i(6, 4) in adj8, "包含 (6,4) 右上")

	# ── 4c: 角落边界（0,0）──
	var corner := _gm.get_adjacent_positions(Vector2i(0, 0), false)
	_expect(corner.size() == 2, "角落 (0,0) 4方向 = 2 个")
	_expect(Vector2i(1, 0) in corner, "包含 (1,0)")
	_expect(Vector2i(0, 1) in corner, "包含 (0,1)")

	# ── 4d: 边缘（0,5）──
	var edge := _gm.get_adjacent_positions(Vector2i(0, 5), false)
	_expect(edge.size() == 3, "边缘 (0,5) 4方向 = 3 个")
	_expect(Vector2i(1, 5) in edge, "包含 (1,5) 右")
	_expect(Vector2i(0, 4) in edge, "包含 (0,4) 上")
	_expect(Vector2i(0, 6) in edge, "包含 (0,6) 下")

	# ── 4e: get_adjacent_cells 返回 GridCell ──
	var cells := _gm.get_adjacent_cells(Vector2i(0, 0), false)
	_expect(cells.size() == 2, "get_adjacent_cells 返回 2 个")
	_expect(cells[0] is GridCell, "返回的是 GridCell 实例")
	_expect(cells[1] is GridCell, "返回的是 GridCell 实例")

	# ── 4f: get_walkable_adjacent 过滤不可通行 ──
	_gm.set_cell_terrain(Vector2i(1, 0), GridCell.Terrain.WALL)
	var walkable := _gm.get_walkable_adjacent(Vector2i(0, 0), false)
	_expect(walkable.size() == 1, "排除 WALL 后可通行邻格 = 1 个")
	_expect(Vector2i(0, 1) in walkable, "只剩 (0,1)")
	_gm.set_cell_terrain(Vector2i(1, 0), GridCell.Terrain.PLAIN)  # 恢复


# ============================================================
# 5. A* 寻路 — 直线（无障碍）
# ============================================================
func _test_pathfinding_straight() -> void:
	print("\n── 测试 5: A* 直线寻路 ──")

	# ── 水平直线 ──
	var path := _gm.find_path(Vector2i(1, 1), Vector2i(5, 1))
	_expect(path.size() == 4, "水平 4 步 → 路径长度 4")
	_expect(path[0] == Vector2i(2, 1), "第一步 (2,1)")
	_expect(path[3] == Vector2i(5, 1), "最后一步 (5,1)")
	# 验证路径无回头
	_expect(_path_is_monotonic(path, true), "水平路径单调递增")

	# ── 垂直直线 ──
	path = _gm.find_path(Vector2i(3, 8), Vector2i(3, 4))
	_expect(path.size() == 4, "垂直 4 步 → 路径长度 4")
	_expect(path[0] == Vector2i(3, 7), "第一步 (3,7)")
	_expect(path[3] == Vector2i(3, 4), "最后一步 (3,4)")

	# ── 对角方向（L形）──
	path = _gm.find_path(Vector2i(1, 1), Vector2i(3, 4))
	# Manhattan = |3-1| + |4-1| = 5 步
	_expect(path.size() == 5, "对角 5 步 → 路径长度 5")
	_expect(path[path.size() - 1] == Vector2i(3, 4), "终点正确")

	# ── 起点=终点 ──
	path = _gm.find_path(Vector2i(5, 5), Vector2i(5, 5))
	_expect(path.size() == 0, "起点=终点 → 空路径")


# ============================================================
# 6. A* 寻路 — 绕过障碍
# ============================================================
func _test_pathfinding_obstacle() -> void:
	print("\n── 测试 6: A* 绕障寻路 ──")

	# 构建障碍墙: 在 (3,0)~(3,5) 放一列 WALL，顶部留空 (3,6)→ 可绕过
	# 起点 (2,3)，终点 (4,3)，墙挡住了直走路线
	# 路径必须向上或向下绕过
	for y in range(6):
		_gm.set_cell_terrain(Vector2i(3, y), GridCell.Terrain.WALL)

	var path := _gm.find_path(Vector2i(2, 3), Vector2i(4, 3))
	_expect(path.size() > 0, "绕障: 找到路径")
	_expect(path.size() % 2 == 0, "绕障: 路径长度为偶数（上下绕行对称）")

	# 路径中的每个点都不能是 WALL
	var no_wall_in_path := true
	for p in path:
		var c := _gm.get_cell(p)
		if c != null and c.terrain == GridCell.Terrain.WALL:
			no_wall_in_path = false
			break
	_expect(no_wall_in_path, "路径不经过 WALL")

	# 验证路径的第一步和最后一步
	_expect(path[path.size() - 1] == Vector2i(4, 3), "终点到达 (4,3)")

	# ── 清理 ──
	for y in range(6):
		_gm.set_cell_terrain(Vector2i(3, y), GridCell.Terrain.PLAIN)


# ============================================================
# 7. A* 寻路 — 不可达
# ============================================================
func _test_pathfinding_unreachable() -> void:
	print("\n── 测试 7: A* 不可达 ──")

	# 用 WALL 把 (5,5) 四面围死
	var target := Vector2i(5, 5)
	var surrounds := [
		Vector2i(5, 4), Vector2i(6, 5),
		Vector2i(5, 6), Vector2i(4, 5),
	]
	for pos in surrounds:
		_gm.set_cell_terrain(pos, GridCell.Terrain.WALL)

	var path := _gm.find_path(Vector2i(0, 0), target)
	_expect(path.size() == 0, "不可达 → 空路径")

	# 终点本身是 WALL 也不可达
	_gm.set_cell_terrain(Vector2i(8, 8), GridCell.Terrain.WALL)
	path = _gm.find_path(Vector2i(1, 1), Vector2i(8, 8))
	_expect(path.size() == 0, "终点为 WALL → 空路径")

	# ── 清理 ──
	for pos in surrounds:
		_gm.set_cell_terrain(pos, GridCell.Terrain.PLAIN)
	_gm.set_cell_terrain(Vector2i(8, 8), GridCell.Terrain.PLAIN)


# ============================================================
# 8. A* 寻路 — 边界情况
# ============================================================
func _test_pathfinding_edge_cases() -> void:
	print("\n── 测试 8: A* 边界情况 ──")

	# ── 越界起点 ──
	var path := _gm.find_path(Vector2i(-1, -1), Vector2i(5, 5))
	_expect(path.size() == 0, "越界起点 → 空路径")

	# ── 越界终点 ──
	path = _gm.find_path(Vector2i(1, 1), Vector2i(99, 99))
	_expect(path.size() == 0, "越界终点 → 空路径")

	# ── 地形消耗 — A* 会选择更短的实际代价路径 ──
	# 路径1（绕道平原）: (2,0)→(2,1)→(3,1)→(3,0)  代价=3.0，距离=3
	# 路径2（穿森林）: (2,0)→(2,1)→(2,2)   ...  let me think more carefully
	# Actually let's test: from (0,0) to (2,0). Direct path is (0,0)→(1,0)→(2,0), cost=2.0
	# If we put FOREST on (1,0) cost 1.5, A* should still prefer direct: (0,0)→(1,0 forest=1.5)→(2,0)
	# total=2.5. Alternative: (0,0)→(0,1)→(1,1)→(2,1)→(2,0) cost=4.0.
	# A* correctly picks the direct path through forest.
	_gm.set_cell_terrain(Vector2i(1, 0), GridCell.Terrain.FOREST)
	path = _gm.find_path(Vector2i(0, 0), Vector2i(2, 0))
	_expect(path.size() == 2, "穿森林: 仍选短路径(代价2.5 vs 绕行4.0)")
	_gm.set_cell_terrain(Vector2i(1, 0), GridCell.Terrain.PLAIN)

	# ── 长距离寻路（对角线）──
	path = _gm.find_path(Vector2i(0, 0), Vector2i(9, 9))
	var expected_len := 18  # |9-0| + |9-0| = 18
	_expect(path.size() == expected_len, "长距离 (0,0)→(9,9) = 18 步")
	_expect(path[expected_len - 1] == Vector2i(9, 9), "长距离终点正确")

	# ── 占用格不可通行 ──
	_gm.occupy_cell(Vector2i(3, 0), 999)
	path = _gm.find_path(Vector2i(2, 0), Vector2i(4, 0))
	_expect(path.size() > 0, "占用格绕行: 找到路径")
	# 路径不应经过 (3,0)
	var passes_occupied := false
	for p in path:
		if p == Vector2i(3, 0):
			passes_occupied = true
	_expect(not passes_occupied, "路径不经过占用格 (3,0)")
	_gm.free_cell(Vector2i(3, 0))


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


## 验证路径在指定方向上单调（用于直线路径测试）
func _path_is_monotonic(path: Array, horizontal: bool) -> bool:
	if path.is_empty():
		return true
	var idx := 0 if horizontal else 1
	var prev: int = path[0][idx]
	for i in range(1, path.size()):
		var cur: int = path[i][idx]
		if horizontal:
			if cur <= prev:
				return false
		else:
			if cur >= prev:
				return false
		prev = cur
	return true


func _print_summary() -> void:
	var total := _tests_passed + _tests_failed
	print("\n" + "=".repeat(60))
	print("  网格测试完成: %d/%d 通过" % [_tests_passed, total])
	if _tests_failed > 0:
		printerr("  %d 项失败:" % _tests_failed)
		for line in _failures:
			printerr("    - %s" % line)
	else:
		print("  🎉 全部通过！")
	print("=".repeat(60))
