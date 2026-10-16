class_name RacePause
extends Control
## Gray veil over a paused race, with a neon pause mark or a countdown number.


const COUNT_FONT: Font = preload("res://ui/fonts/Nunito-ExtraBold.ttf")

var _glow: Color = Color(0.72, 0.48, 1.0)
var _count: String = ""
var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)


func show_mark(glow: Color) -> void:
	_glow = glow
	_count = ""
	visible = true
	_pulse = 0.0
	set_process(true)
	queue_redraw()


func show_count(glow: Color, text: String) -> void:
	_glow = glow
	_count = text
	visible = true
	set_process(false)
	queue_redraw()


func hide_veil() -> void:
	_count = ""
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.45, 0.43, 0.5, 0.62), true)
	var center: Vector2 = size * 0.5
	if _count != "":
		_draw_count(center)
	else:
		_draw_mark(center)


func _draw_mark(center: Vector2) -> void:
	var breathe: float = 0.5 + 0.5 * sin(_pulse * 2.1)
	var ring: Color = _glow.lerp(Color.WHITE, 0.42)
	var halo: Color = _glow
	halo.a = 0.2 + breathe * 0.18
	draw_arc(center, 88.0, 0.0, TAU, 72, halo, 18.0, true)
	draw_arc(center, 78.0, 0.0, TAU, 72, ring, 3.0, true)
	_draw_bar(center + Vector2(-18.0, 0.0), ring, halo)
	_draw_bar(center + Vector2(18.0, 0.0), ring, halo)


func _draw_bar(center: Vector2, ink: Color, halo: Color) -> void:
	var half: float = 26.0
	var top: Vector2 = center + Vector2(0.0, -half)
	var bottom: Vector2 = center + Vector2(0.0, half)
	draw_line(top, bottom, halo, 16.0, true)
	draw_line(top, bottom, ink, 7.0, true)
	draw_circle(top, 3.5, ink)
	draw_circle(bottom, 3.5, ink)


func _draw_count(center: Vector2) -> void:
	var font_size: int = 168
	var width: float = COUNT_FONT.get_string_size(_count, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var ascent: float = COUNT_FONT.get_ascent(font_size)
	var descent: float = COUNT_FONT.get_descent(font_size)
	var pos := Vector2(center.x - width * 0.5, center.y + (ascent - descent) * 0.5)
	var halo: Color = _glow
	halo.a = 0.55
	draw_string(COUNT_FONT, pos + Vector2(0.0, 3.0), _count, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, halo)
	draw_string(COUNT_FONT, pos, _count, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _glow.lerp(Color.WHITE, 0.62))
