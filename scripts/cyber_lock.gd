class_name CyberLock
extends Control
## Neon cell gate. Taps pass through; the board blocks input while locked.

const COLOR_LOCKED: Color = Color(1.0, 0.18, 0.42)
const COLOR_OPEN: Color = Color(0.18, 1.0, 0.55)

var cell_index: int = -1
var open: bool = false

var _pulse: float = 0.0
var _blend: float = 0.0
var _deny: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	clip_contents = false
	set_process(true)


func set_open(value: bool) -> void:
	if open == value:
		return
	open = value
	set_process(true)
	queue_redraw()


func nudge_deny() -> void:
	if open:
		return
	_deny = 1.0
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_pulse += delta
	if open:
		_blend = minf(_blend + delta * 5.2, 1.0)
	else:
		_blend = maxf(_blend - delta * 6.4, 0.0)
	if _deny > 0.0:
		_deny = maxf(_deny - delta * 3.8, 0.0)
	queue_redraw()


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	var shake := Vector2(sin(_pulse * 52.0) * 2.4 * _deny, 0.0)
	draw_set_transform_matrix(Transform2D(0.0, shake))
	var pad: float = minf(size.x, size.y) * 0.08
	var frame := Rect2(Vector2(pad, pad), size - Vector2(pad, pad) * 2.0)
	var glow: float = 0.72 + 0.28 * sin(_pulse * (4.2 if open else 3.1) + float(cell_index) * 0.35)
	var tint: Color = COLOR_LOCKED.lerp(COLOR_OPEN, _blend)
	var wash := tint
	wash.a = (0.1 + 0.08 * glow) * (1.0 if open else 1.15)
	draw_rect(frame, wash, true)
	var outer := tint
	outer.a = 0.22 * glow
	draw_rect(frame.grow(2.4), outer, false, 3.4, true)
	var edge := tint
	edge.a = 0.55 + 0.4 * glow
	draw_rect(frame, edge, false, 1.7, true)
	_draw_corners(frame, tint, glow)
	_draw_latch(frame, tint, glow)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_corners(frame: Rect2, tint: Color, glow: float) -> void:
	var arm: float = minf(frame.size.x, frame.size.y) * 0.28
	var width: float = maxf(2.0, minf(frame.size.x, frame.size.y) * 0.055)
	var core := tint.lerp(Color.WHITE, 0.35 + 0.25 * glow)
	core.a = 0.95
	var halo := tint
	halo.a = 0.35 * glow
	var points: Array[Vector2] = [
		frame.position,
		Vector2(frame.end.x, frame.position.y),
		frame.end,
		Vector2(frame.position.x, frame.end.y),
	]
	var inward: Array[Vector2] = [
		Vector2(1.0, 1.0),
		Vector2(-1.0, 1.0),
		Vector2(-1.0, -1.0),
		Vector2(1.0, -1.0),
	]
	for corner in 4:
		var origin: Vector2 = points[corner]
		var dir: Vector2 = inward[corner]
		var a: Vector2 = origin + Vector2(arm * dir.x, 0.0)
		var b: Vector2 = origin + Vector2(0.0, arm * dir.y)
		draw_line(origin, a, halo, width * 2.4, true)
		draw_line(origin, b, halo, width * 2.4, true)
		draw_line(origin, a, core, width, true)
		draw_line(origin, b, core, width, true)


func _draw_latch(frame: Rect2, tint: Color, glow: float) -> void:
	var body_w: float = minf(frame.size.x, frame.size.y) * (0.22 if open else 0.26)
	var body_h: float = body_w * 0.72
	var center: Vector2 = frame.get_center()
	var body := Rect2(center - Vector2(body_w, body_h) * 0.5 + Vector2(0.0, body_h * 0.18), Vector2(body_w, body_h))
	var line: float = maxf(1.6, body_w * 0.14)
	var core := tint.lerp(Color.WHITE, 0.2)
	core.a = 0.55 + 0.4 * glow if not open else 0.22 + 0.2 * glow
	var shackle_c := Vector2(center.x, body.position.y)
	var radius: float = body_w * 0.36
	if open:
		draw_arc(shackle_c + Vector2(radius * 0.55, 0.0), radius, -PI * 0.2, PI * 0.85, 18, core, line, true)
	else:
		draw_arc(shackle_c, radius, PI, TAU, 16, core, line, true)
	draw_rect(body, core, false, line, true)
	if not open:
		var pin := tint.lerp(Color.WHITE, 0.45)
		pin.a = core.a
		draw_circle(body.get_center(), maxf(1.1, line * 0.55), pin)
