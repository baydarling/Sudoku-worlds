class_name MenuGlyph
extends Control
## Tiny 3x3 mark for the home logo.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(64.0, 64.0)


func _draw() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	var gold := Color(0.93, 0.78, 0.42, 0.95)
	var dim := Color(0.93, 0.78, 0.42, 0.22)
	var pad: float = 3.0
	var grid: float = minf(size.x, size.y) - pad * 2.0
	var origin := Vector2((size.x - grid) * 0.5, (size.y - grid) * 0.5)
	var cell: float = grid / 3.0
	var filled: Array[Vector2i] = [Vector2i(0, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(2, 2)]
	for cell_pos in filled:
		var rect := Rect2(origin + Vector2(float(cell_pos.x), float(cell_pos.y)) * cell + Vector2(3.0, 3.0), Vector2(cell - 6.0, cell - 6.0))
		draw_rect(rect, dim, true)
	for line in 4:
		var along: float = float(line) * cell
		var width: float = 2.4 if line % 3 == 0 else 1.2
		draw_line(origin + Vector2(along, 0.0), origin + Vector2(along, grid), gold, width, true)
		draw_line(origin + Vector2(0.0, along), origin + Vector2(grid, along), gold, width, true)
