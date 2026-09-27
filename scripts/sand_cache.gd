class_name SandCache
extends Control
## A gentle Desert objective: solve this marked cell to uncover its gold.

var cell_index: int = -1
var bounty: int = 0
var resolved: bool = false

var _time: float = 0.0
var _reveal: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	clip_contents = true
	set_process(true)


func set_resolved(value: bool) -> void:
	if resolved == value:
		return
	resolved = value
	if resolved:
		_reveal = 0.0
		visible = true
	else:
		_reveal = 0.0
		modulate = Color.WHITE
		visible = true
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if resolved:
		_reveal = minf(_reveal + delta * 2.4, 1.0)
		modulate = Color(1.0, 0.9, 0.55, 1.0 - _reveal)
		if _reveal >= 1.0:
			visible = false
			set_process(false)
			return
	queue_redraw()


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	var unit: float = minf(size.x, size.y)
	var center := size * 0.5
	var pulse: float = 0.5 + 0.5 * sin(_time * 2.2 + float(cell_index) * 0.41)
	var fade: float = 1.0 - _reveal
	var sand_dark := Color(0.58, 0.3, 0.06, 0.64 * fade)
	var sand := Color(0.94, 0.62, 0.16, (0.62 + pulse * 0.16) * fade)
	var sand_lit := Color(1.0, 0.82, 0.36, 0.82 * fade)
	var mound := PackedVector2Array([
		Vector2(unit * 0.08, unit * 0.78),
		Vector2(unit * 0.2, unit * 0.57),
		Vector2(unit * 0.38, unit * 0.48),
		Vector2(unit * 0.52, unit * 0.55),
		Vector2(unit * 0.68, unit * 0.45),
		Vector2(unit * 0.9, unit * 0.76),
		Vector2(unit * 0.9, unit * 0.9),
		Vector2(unit * 0.08, unit * 0.9),
	])
	draw_colored_polygon(mound, sand_dark)
	draw_polyline(mound, sand, maxf(1.5, unit * 0.035), true)
	draw_arc(center + Vector2(0.0, unit * 0.08), unit * 0.19, 0.0, TAU, 28, sand_lit, maxf(2.0, unit * 0.045), true)
	var glint := Color(1.0, 0.94, 0.58, (0.55 + pulse * 0.45) * fade)
	draw_line(center + Vector2(-unit * 0.1, unit * 0.08), center + Vector2(unit * 0.1, unit * 0.08), glint, maxf(1.3, unit * 0.025), true)
	draw_line(center + Vector2(0.0, -unit * 0.02), center + Vector2(0.0, unit * 0.18), glint, maxf(1.3, unit * 0.025), true)
	if bounty > 0 and not resolved:
		_draw_bounty(fade)


func _draw_bounty(fade: float) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var text: String = "+%d" % bounty
	var font_size: int = maxi(11, int(minf(size.x, size.y) * 0.2))
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var draw_at := Vector2((size.x - text_size.x) * 0.5, size.y * 0.28)
	var gold := Color(1.0, 0.88, 0.4, 0.96 * fade)
	var shadow := Color(0.12, 0.045, 0.0, 0.8 * fade)
	draw_string(font, draw_at + Vector2(0.0, 1.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, shadow)
	draw_string(font, draw_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, gold)
