class_name EmberRush
extends Control
## Flames from both screen edges and a center OVERHEAT title.

const LIFE: float = 1.15

var _life: float = 0.0
var _note: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	visible = false
	set_process(false)


func play(note: String = "") -> void:
	_note = note
	_life = LIFE
	visible = true
	set_process(true)
	queue_redraw()


func stop() -> void:
	_life = 0.0
	_note = ""
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_life = maxf(0.0, _life - delta)
	queue_redraw()
	if _life <= 0.0:
		stop()


func _draw() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	var travel: float = 1.0 - clampf(_life / LIFE, 0.0, 1.0)
	var fade: float = 1.0 - travel * travel
	_draw_side(true, fade)
	_draw_side(false, fade)
	_draw_title(fade, travel)


func _draw_side(left: bool, fade: float) -> void:
	var reach: float = size.x * 0.2 * fade
	var tongues: int = 8
	for index in tongues:
		var ny: float = (float(index) + 0.5) / float(tongues)
		var y: float = size.y * ny
		var flicker: float = 0.72 + 0.28 * sin(_life * 30.0 + float(index) * 1.8)
		var half: float = size.y * 0.055 * flicker
		var depth: float = reach * (0.62 + 0.38 * flicker)
		var edge_x: float = 0.0 if left else size.x
		var sign: float = 1.0 if left else -1.0
		var tip := Vector2(edge_x + sign * depth, y + sin(_life * 18.0 + float(index)) * 8.0)
		var outer := PackedVector2Array([
			tip,
			Vector2(edge_x, y - half),
			Vector2(edge_x, y + half),
		])
		draw_colored_polygon(outer, Color(1.0, 0.28, 0.04, 0.7 * fade))
		var core := PackedVector2Array([
			tip.lerp(Vector2(edge_x, y), 0.42),
			Vector2(edge_x, y - half * 0.36),
			Vector2(edge_x, y + half * 0.36),
		])
		draw_colored_polygon(core, Color(1.0, 0.92, 0.48, 0.82 * fade))
	var wash := Color(1.0, 0.16, 0.02, 0.16 * fade)
	var band: float = reach * 0.5
	if left:
		draw_rect(Rect2(0.0, 0.0, band, size.y), wash, true)
	else:
		draw_rect(Rect2(size.x - band, 0.0, band, size.y), wash, true)


func _draw_title(fade: float, travel: float) -> void:
	var font: Font = get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font
	var pop: float = 1.0 - pow(1.0 - minf(travel / 0.16, 1.0), 3.0)
	var font_size: int = int(clampf(size.x * 0.092, 40.0, 68.0) * lerpf(0.84, 1.0, pop))
	var text := "OVERHEAT"
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var center: Vector2 = size * 0.5
	var baseline: float = (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var at := Vector2(center.x - text_size.x * 0.5, center.y + baseline)
	var color := Color(1.0, 0.88, 0.42, fade)
	var shadow := Color(0.18, 0.02, 0.0, 0.72 * fade)
	draw_string(font, at + Vector2(0.0, 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, shadow)
	draw_string(font, at + Vector2(-1.5, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1.0, 0.42, 0.08, 0.45 * fade))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
	if _note.is_empty():
		return
	var note_size: int = maxi(18, int(float(font_size) * 0.42))
	var note_size_v: Vector2 = font.get_string_size(_note, HORIZONTAL_ALIGNMENT_LEFT, -1.0, note_size)
	var note_at := Vector2(center.x - note_size_v.x * 0.5, at.y + float(font_size) * 0.72)
	draw_string(font, note_at, _note, HORIZONTAL_ALIGNMENT_LEFT, -1.0, note_size, Color(1.0, 0.62, 0.28, fade))
