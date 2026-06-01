# ============================================================
# GridManager - 二维网格管理器
# ============================================================
# 挂载场景: 主场景根节点（非 Autoload，由场景管理生命周期）
#
# 职责:
#   - 创建并维护 20×20 二维网格（GridCell 数组）
#   - 格子占用/释放
#   - 相邻格子查询
#   - A* 寻路（曼哈顿距离启发式，4方向移动）
#
# 依赖:
#   - GameConfig（Autoload）: 网格尺寸常量
#   - EventBus（Autoload）: 广播网格变更信号
#   - GridCell（Resource）: 单元格数据
# ============================================================
extends Node


# ──────────────────────────────────────────
# 信号
# ──────────────────────────────────────────

## 网格初始化完成
signal grid_initialized()

## 某格子的数据发生了变化（占用/释放/地形变更）
signal cell_changed(position: Vector2i)


# ──────────────────────────────────────────
# 属性
# ──────────────────────────────────────────

## 网格宽度
var grid_width: int = 20

## 网格高度
var grid_height: int = 20

## 网格数据: 二维数组 _cells[y][x] → GridCell
var _cells: Array = []


# ──────────────────────────────────────────
# 生命周期
# ──────────────────────────────────────────

func _ready() -> void:
	print("[GridManager] ✅ 网格管理器已就绪")


# ──────────────────────────────────────────
# 初始化
# ──────────────────────────────────────────

## 初始化网格
## @param width: 网格宽度（默认使用 GameConfig.DEFAULT_GRID_WIDTH）
## @param height: 网格高度（默认使用 GameConfig.DEFAULT_GRID_HEIGHT）
func initialize(width: int = -1, height: int = -1) -> void:
	grid_width = width if width > 0 else GameConfig.DEFAULT_GRID_WIDTH
	grid_height = height if height > 0 else GameConfig.DEFAULT_GRID_HEIGHT

	print("[GridManager] 🏗 初始化网格 %d×%d ..." % [grid_width, grid_height])

	_cells.clear()
	_cells.resize(grid_height)

	for y in range(grid_height):
		_cells[y] = []
		_cells[y].resize(grid_width)
		for x in range(grid_width):
			var cell := GridCell.new()
			cell.grid_position = Vector2i(x, y)
			cell.terrain = GridCell.Terrain.PLAIN
			_cells[y][x] = cell

	print("[GridManager]   网格初始化完成，共 %d 个格子" % (grid_width * grid_height))
	grid_initialized.emit()
	EventBus.grid_ready.emit()


## 重新随机生成地形（用于测试 / 地图随机化）
## @param seed_val: 随机种子（0 表示不设置）
func generate_random_terrain(seed_val: int = 0) -> void:
	if seed_val != 0:
		seed(seed_val)

	var terrain_weights := [
		{ "type": GridCell.Terrain.PLAIN,    "weight": 60 },
		{ "type": GridCell.Terrain.FOREST,   "weight": 20 },
		{ "type": GridCell.Terrain.MOUNTAIN, "weight": 12 },
		{ "type": GridCell.Terrain.WATER,    "weight": 6 },
		{ "type": GridCell.Terrain.WALL,     "weight": 2 },
	]

	var total_weight := 0
	for t in terrain_weights:
		total_weight += t.weight

	for y in range(grid_height):
		for x in range(grid_width):
			var roll := randi() % total_weight
			var cumulative := 0
			for t in terrain_weights:
				cumulative += t.weight
				if roll < cumulative:
					_cells[y][x].terrain = t.type
					break
			EventBus.grid_cell_updated.emit(Vector2i(x, y))

	print("[GridManager] 🎲 地形随机化完成")


# ──────────────────────────────────────────
# 格子访问
# ──────────────────────────────────────────

## 获取指定坐标的 GridCell
## @return GridCell，若越界返回 null
func get_cell(pos: Vector2i) -> GridCell:
	if not is_within_bounds(pos):
		return null
	return _cells[pos.y][pos.x]


## 判断坐标是否在网格范围内
func is_within_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height


## 判断指定格子是否被占用
func is_cell_occupied(pos: Vector2i) -> bool:
	var cell := get_cell(pos)
	if cell == null:
		return true   # 越界视为"不可用"→返回占用
	return cell.is_occupied


## 判断指定格子是否可通行
func is_cell_walkable(pos: Vector2i) -> bool:
	var cell := get_cell(pos)
	if cell == null:
		return false
	return cell.is_walkable() and not cell.is_occupied


# ──────────────────────────────────────────
# 格子操作
# ──────────────────────────────────────────

## 占用一个格子
## @return true 表示占用成功，false 表示无法占用（越界/已被占用）
func occupy_cell(pos: Vector2i, unit_id: int) -> bool:
	var cell := get_cell(pos)
	if cell == null or cell.is_occupied:
		return false

	cell.occupy(unit_id)
	cell_changed.emit(pos)
	EventBus.grid_cell_updated.emit(pos)
	return true


## 释放一个格子
func free_cell(pos: Vector2i) -> void:
	var cell := get_cell(pos)
	if cell == null:
		return

	cell.release()
	cell_changed.emit(pos)
	EventBus.grid_cell_updated.emit(pos)


## 设置格子地形
func set_cell_terrain(pos: Vector2i, terrain: GridCell.Terrain) -> void:
	var cell := get_cell(pos)
	if cell == null:
		return
	cell.terrain = terrain
	cell_changed.emit(pos)
	EventBus.grid_cell_updated.emit(pos)


# ──────────────────────────────────────────
# 相邻格子
# ──────────────────────────────────────────

## 获取相邻格子的坐标列表
## @param pos: 中心坐标
## @param diagonal: 是否包含对角线（默认仅4方向）
## @return Array[Vector2i] 有效相邻坐标
func get_adjacent_positions(pos: Vector2i, diagonal: bool = false) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	var directions: Array[Vector2i] = [
		Vector2i(0, -1),   # 上
		Vector2i(1, 0),    # 右
		Vector2i(0, 1),    # 下
		Vector2i(-1, 0),   # 左
	]

	if diagonal:
		directions.append_array([
			Vector2i(-1, -1),  # 左上
			Vector2i(1, -1),   # 右上
			Vector2i(-1, 1),   # 左下
			Vector2i(1, 1),    # 右下
		])

	for dir in directions:
		var neighbor := pos + dir
		if is_within_bounds(neighbor):
			result.append(neighbor)

	return result


## 获取相邻的 GridCell 列表
## @param pos: 中心坐标
## @param diagonal: 是否包含对角线
## @return Array[GridCell]
func get_adjacent_cells(pos: Vector2i, diagonal: bool = false) -> Array:
	var result: Array = []
	for npos in get_adjacent_positions(pos, diagonal):
		result.append(get_cell(npos))
	return result


## 获取相邻且可通行的格子坐标
## @return Array[Vector2i]
func get_walkable_adjacent(pos: Vector2i, diagonal: bool = false) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for npos in get_adjacent_positions(pos, diagonal):
		if is_cell_walkable(npos):
			result.append(npos)
	return result


# ──────────────────────────────────────────
# 距离计算
# ──────────────────────────────────────────

## 曼哈顿距离
static func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


## 切比雪夫距离（对角线移动时使用）
static func chebyshev_distance(a: Vector2i, b: Vector2i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y))


# ──────────────────────────────────────────
# A* 寻路
# ──────────────────────────────────────────

## A* 寻路（4方向移动，曼哈顿距离启发式）
## @param from: 起点坐标
## @param to: 终点坐标
## @return Array[Vector2i] 路径坐标序列（不含起点），若不可达返回空数组
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	# ── 边界检查 ──
	if not is_within_bounds(from) or not is_within_bounds(to):
		print("[GridManager] ⚠ 寻路失败：起点或终点越界")
		return []

	if from == to:
		return []

	if not is_cell_walkable(to):
		print("[GridManager] ⚠ 寻路失败：终点不可通行 %s" % to)
		return []

	# ── A* 数据结构 ──
	# g_score[pos] = 从起点到 pos 的实际代价
	# f_score[pos] = g_score[pos] + heuristic(pos, to)
	var g_score: Dictionary = {}
	var f_score: Dictionary = {}
	var came_from: Dictionary = {}   # pos → 前驱坐标
	var open_set: Array = [from]     # 待探索列表（用 Array + 排序模拟优先队列）

	g_score[from] = 0.0
	f_score[from] = manhattan_distance(from, to)

	# ── 主循环 ──
	while not open_set.is_empty():
		# 取出 f_score 最小的节点
		var current := _pop_lowest_f(open_set, f_score)

		if current == to:
			return _reconstruct_path(came_from, current)

		# 遍历4方向邻居
		for neighbor in get_adjacent_positions(current, false):
			if not is_cell_walkable(neighbor):
				continue

			# 移动代价 = 目标格的 terrain 消耗
			var cell := get_cell(neighbor)
			var move_cost := cell.get_movement_cost()
			if move_cost >= INF * 0.5:   # 浮点 INF 检查
				continue

			var tentative_g: float = g_score[current] + move_cost

			if not g_score.has(neighbor) or tentative_g < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + manhattan_distance(neighbor, to)

				if not open_set.has(neighbor):
					open_set.append(neighbor)

	# 不可达
	print("[GridManager] ⚠ 寻路失败：%s → %s 不可达" % [from, to])
	return []


# ──────────────────────────────────────────
# 内部辅助
# ──────────────────────────────────────────

## 从 open_set 中取出 f_score 最小的元素
func _pop_lowest_f(open_set: Array, f_score: Dictionary) -> Vector2i:
	var best_idx := 0
	var best_f: float = f_score[open_set[0]]

	for i in range(1, open_set.size()):
		var f: float = f_score[open_set[i]]
		if f < best_f:
			best_f = f
			best_idx = i

	var result: Vector2i = open_set[best_idx]
	open_set.remove_at(best_idx)
	return result


## 从 came_from 字典重建路径
func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []

	while came_from.has(current):
		path.insert(0, current)
		current = came_from[current]

	# path 不含起点 current，只含从起点下一步开始的坐标序列
	return path


# ──────────────────────────────────────────
# 调试
# ──────────────────────────────────────────

## 打印网格文本图（调试用）
func debug_print_grid(show_terrain: bool = true) -> void:
	print("── 网格 %d×%d ──" % [grid_width, grid_height])
	for y in range(grid_height):
		var line := ""
		for x in range(grid_width):
			var cell: GridCell = _cells[y][x]
			if show_terrain:
				match cell.terrain:
					GridCell.Terrain.PLAIN:    line += ". "
					GridCell.Terrain.FOREST:   line += "♣ "
					GridCell.Terrain.MOUNTAIN: line += "▲ "
					GridCell.Terrain.WATER:    line += "≈ "
					GridCell.Terrain.WALL:     line += "█ "
			else:
				line += "X " if cell.is_occupied else ". "
		print("  %s" % line)
