class_name SudokuGenerator
extends RefCounted
## Creates random Sudoku puzzles that are guaranteed to have exactly one solution.
## 9 is classic 3x3 boxes. 4 is mini 2x2 boxes. 6 is wide 2x3 boxes.

const CLASSIC_SIZE: int = 9
const MINI_SIZE: int = 4
const WIDE_SIZE: int = 6


## A generated puzzle: the board shown to the player plus its full solution.
class Puzzle extends RefCounted:
	var givens: Array[int] = []
	var solution: Array[int] = []
	var grid_size: int = CLASSIC_SIZE


var _grid_size: int = CLASSIC_SIZE
var _box_width: int = 3
var _box_height: int = 3
var _cell_count: int = 81
var _digit_mask: int = 0x1FF
## Remaining uniqueness-search steps. `-1` means unlimited.
var _search_budget: int = -1


static func normalize_size(grid_size: int) -> int:
	if grid_size == MINI_SIZE or grid_size == WIDE_SIZE:
		return grid_size
	return CLASSIC_SIZE


## Box width (x) and height (y) for a legal Sudoku size.
static func box_dims(grid_size: int) -> Vector2i:
	match normalize_size(grid_size):
		MINI_SIZE:
			return Vector2i(2, 2)
		WIDE_SIZE:
			return Vector2i(3, 2)
		_:
			return Vector2i(3, 3)


static func generate(empty_cells: int = 45, grid_size: int = CLASSIC_SIZE, search_budget: int = -1) -> Puzzle:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return generate_with_rng(empty_cells, rng, grid_size, search_budget)


static func generate_with_rng(empty_cells: int, rng: RandomNumberGenerator, grid_size: int = CLASSIC_SIZE, search_budget: int = -1) -> Puzzle:
	var gen := SudokuGenerator.new()
	return gen._generate(empty_cells, rng, grid_size, search_budget)


func _generate(empty_cells: int, rng: RandomNumberGenerator, grid_size: int, search_budget: int = -1) -> Puzzle:
	_search_budget = search_budget
	_set_size(grid_size)
	var puzzle := Puzzle.new()
	puzzle.grid_size = _grid_size
	puzzle.solution = _build_full_grid(rng)
	puzzle.givens = _carve_holes(puzzle.solution, empty_cells, rng)
	return puzzle


func _set_size(grid_size: int) -> void:
	_grid_size = normalize_size(grid_size)
	var dims: Vector2i = box_dims(_grid_size)
	_box_width = dims.x
	_box_height = dims.y
	_cell_count = _grid_size * _grid_size
	_digit_mask = (1 << _grid_size) - 1


func _build_full_grid(rng: RandomNumberGenerator) -> Array[int]:
	var grid: Array[int] = []
	grid.resize(_cell_count)
	var rows: Array[int] = []
	rows.resize(_grid_size)
	var columns: Array[int] = []
	columns.resize(_grid_size)
	var boxes: Array[int] = []
	boxes.resize(_grid_size)
	_fill_cell(grid, rows, columns, boxes, 0, rng)
	return grid


func _fill_cell(grid: Array[int], rows: Array[int], columns: Array[int], boxes: Array[int], index: int, rng: RandomNumberGenerator) -> bool:
	if index == _cell_count:
		return true
	var row: int = _row_of(index)
	var column: int = _column_of(index)
	var box: int = _box_of(index)
	var available: int = _digit_mask & ~(rows[row] | columns[column] | boxes[box])
	for digit in _shuffled_digits(available, rng):
		var bit: int = 1 << (digit - 1)
		grid[index] = digit
		rows[row] |= bit
		columns[column] |= bit
		boxes[box] |= bit
		if _fill_cell(grid, rows, columns, boxes, index + 1, rng):
			return true
		rows[row] &= ~bit
		columns[column] &= ~bit
		boxes[box] &= ~bit
		grid[index] = 0
	return false


## Blanks out cells one by one, keeping a cell only if the puzzle stays unique.
func _carve_holes(solution: Array[int], empty_cells: int, rng: RandomNumberGenerator) -> Array[int]:
	var givens: Array[int] = solution.duplicate()
	var order: Array[int] = []
	for index in _cell_count:
		order.append(index)
	_shuffle(order, rng)
	var removed: int = 0
	var target: int = mini(empty_cells, _cell_count - _grid_size)
	for index in order:
		if removed >= target:
			break
		var value: int = givens[index]
		givens[index] = 0
		if _count_solutions(givens, 2) == 1:
			removed += 1
		else:
			givens[index] = value
	return givens


## Counts solutions, giving up as soon as `limit` of them have been found.
func _count_solutions(givens: Array[int], limit: int) -> int:
	var grid: Array[int] = givens.duplicate()
	var rows: Array[int] = []
	rows.resize(_grid_size)
	var columns: Array[int] = []
	columns.resize(_grid_size)
	var boxes: Array[int] = []
	boxes.resize(_grid_size)
	for index in _cell_count:
		var digit: int = grid[index]
		if digit == 0:
			continue
		var bit: int = 1 << (digit - 1)
		rows[_row_of(index)] |= bit
		columns[_column_of(index)] |= bit
		boxes[_box_of(index)] |= bit
	return _search(grid, rows, columns, boxes, limit)


func _search(grid: Array[int], rows: Array[int], columns: Array[int], boxes: Array[int], limit: int) -> int:
	if _search_budget == 0:
		return 2
	if _search_budget > 0:
		_search_budget -= 1
	var best_index: int = -1
	var best_mask: int = 0
	var best_count: int = _grid_size + 1
	for index in _cell_count:
		if grid[index] != 0:
			continue
		var available: int = _digit_mask & ~(rows[_row_of(index)] | columns[_column_of(index)] | boxes[_box_of(index)])
		var count: int = _count_bits(available)
		if count == 0:
			return 0
		if count < best_count:
			best_count = count
			best_index = index
			best_mask = available
			if count == 1:
				break
	if best_index == -1:
		return 1
	var row: int = _row_of(best_index)
	var column: int = _column_of(best_index)
	var box: int = _box_of(best_index)
	var total: int = 0
	for digit in range(1, _grid_size + 1):
		var bit: int = 1 << (digit - 1)
		if best_mask & bit == 0:
			continue
		grid[best_index] = digit
		rows[row] |= bit
		columns[column] |= bit
		boxes[box] |= bit
		total += _search(grid, rows, columns, boxes, limit - total)
		rows[row] &= ~bit
		columns[column] &= ~bit
		boxes[box] &= ~bit
		grid[best_index] = 0
		if total >= limit:
			break
	return total


func _shuffled_digits(mask: int, rng: RandomNumberGenerator) -> Array[int]:
	var digits: Array[int] = []
	for digit in range(1, _grid_size + 1):
		if mask & (1 << (digit - 1)) != 0:
			digits.append(digit)
	_shuffle(digits, rng)
	return digits


func _shuffle(values: Array[int], rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swapped: int = values[i]
		values[i] = values[j]
		values[j] = swapped


func _count_bits(mask: int) -> int:
	var count: int = 0
	var value: int = mask
	while value != 0:
		value &= value - 1
		count += 1
	return count


@warning_ignore("integer_division")
func _row_of(index: int) -> int:
	return index / _grid_size


func _column_of(index: int) -> int:
	return index % _grid_size


@warning_ignore("integer_division")
func _box_of(index: int) -> int:
	var boxes_across: int = _grid_size / _box_width
	return (index / (_grid_size * _box_height)) * boxes_across + (index % _grid_size) / _box_width
