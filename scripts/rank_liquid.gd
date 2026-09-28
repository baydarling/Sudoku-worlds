class_name RankLiquid
extends Control
## Glass tube under the rank hint. Gold liquid is the stars already earned toward the next rank.


var _filled: int = 0
var _needed: int = 1
var _wave: float = 0.0
var _glass: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glass = StyleBoxFlat.new()
	_glass.bg_color = Color(0.07, 0.04, 0.1, 1.0)
	_glass.border_color = Color(0.93, 0.78, 0.42, 0.55)
	_glass.set_border_width_all(2)
	_glass.set_corner_radius_all(12)
	set_process(is_visible_in_tree())


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process(is_visible_in_tree())
	elif what == NOTIFICATION_RESIZED:
		queue_redraw()


func set_progress(filled: int, needed: int) -> void:
	_filled = maxi(0, filled)
	_needed = maxi(1, needed)
	queue_redraw()


func _process(delta: float) -> void:
	_wave += delta
	queue_redraw()


func _draw() -> void:
	if _glass == null or size.x < 8.0:
		return
	var bar_h: float = 26.0
	var bar := Rect2(0.0, (size.y - bar_h) * 0.5, size.x, bar_h)
	_glass.draw(get_canvas_item(), bar)
	var inner := bar.grow_individual(-4.0, -4.0, -4.0, -4.0)
	var ratio: float = clampf(float(_filled) / float(_needed), 0.0, 1.0)
	if ratio <= 0.001:
		return
	var width: float = maxf(inner.size.y, inner.size.x * ratio)
	width = minf(width, inner.size.x)
	_draw_liquid(inner, width)


func _draw_liquid(inner: Rect2, width: float) -> void:
	var top: float = inner.position.y
	var bottom: float = inner.end.y
	var left: float = inner.position.x
	var right: float = inner.position.x + width
	var radius: float = (bottom - top) * 0.5
	var amp: float = minf(2.1, radius * 0.28)
	var columns: int = maxi(12, int(width / 8.0))
	var light := Color(1.0, 0.86, 0.46, 1.0)
	var deep := Color(0.82, 0.52, 0.14, 1.0)
	var lip := Color(1.0, 0.96, 0.78, 0.72)
	for column in columns:
		var t0: float = float(column) / float(columns)
		var t1: float = float(column + 1) / float(columns)
		var x0: float = lerpf(left, right, t0)
		var x1: float = lerpf(left, right, t1)
		var y0: float = _surface_y(t0, top, amp)
		var y1: float = _surface_y(t1, top, amp)
		var floor0: float = bottom - _cap_inset(x0, left, right, radius)
		var floor1: float = bottom - _cap_inset(x1, left, right, radius)
		y0 = maxf(y0, top + _cap_inset(x0, left, right, radius))
		y1 = maxf(y1, top + _cap_inset(x1, left, right, radius))
		if floor0 - y0 < 1.0 and floor1 - y1 < 1.0:
			continue
		var mid0: float = lerpf(y0, floor0, 0.38)
		var mid1: float = lerpf(y1, floor1, 0.38)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x0, y0), Vector2(x1, y1), Vector2(x1, mid1), Vector2(x0, mid0)
		]), light)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x0, mid0), Vector2(x1, mid1), Vector2(x1, floor1), Vector2(x0, floor0)
		]), deep)
		draw_line(Vector2(x0, y0), Vector2(x1, y1), lip, 1.6, true)
	if width < 28.0:
		return
	for index in 3:
		var phase: float = fposmod(_wave * 0.32 + float(index) * 0.37, 1.0)
		var bubble_x: float = left + 10.0 + fmod(float(index) * 46.0, maxf(width - 20.0, 1.0))
		var bubble_y: float = bottom - 4.0 - phase * ((bottom - top) - 6.0)
		bubble_y = clampf(bubble_y, _surface_y((bubble_x - left) / width, top, amp) + 3.0, bottom - 3.0)
		var alpha: float = sin(phase * PI) * 0.42
		draw_circle(Vector2(bubble_x, bubble_y), 1.8, Color(1.0, 0.96, 0.82, alpha))


func _surface_y(along: float, top: float, amp: float) -> float:
	var crest: float = sin(along * TAU * 1.2 + _wave * 1.7) * amp
	crest += sin(along * TAU * 2.3 - _wave * 2.4) * amp * 0.35
	return top + amp + 0.6 + crest


func _cap_inset(x: float, left: float, right: float, radius: float) -> float:
	var edge: float = minf(x - left, right - x)
	if edge >= radius:
		return 0.0
	var dx: float = radius - edge
	return radius - sqrt(maxf(radius * radius - dx * dx, 0.0))
