class_name WinStars
extends Control
## Three clear-screen stars. Earned ones take the world's light.

var earned: int = 0
var ink: Color = Color(1.0, 0.86, 0.46)

var _reveal: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_process(false)


func set_result(count: int, color: Color) -> void:
	earned = clampi(count, 0, 3)
	ink = color
	queue_redraw()


func play() -> void:
	_reveal = 0.0
	visible = true
	set_process(true)
	queue_redraw()


func stop() -> void:
	_reveal = 1.0
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_reveal = minf(1.0, _reveal + delta / 0.62)
	queue_redraw()
	if _reveal >= 1.0:
		set_process(false)


func _draw() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	var mid_y: float = size.y * 0.58
	var slots: Array[Vector2] = [
		Vector2(size.x * 0.2, mid_y + 10.0),
		Vector2(size.x * 0.5, mid_y - 16.0),
		Vector2(size.x * 0.8, mid_y + 10.0),
	]
	var radii: Array[float] = [size.y * 0.28, size.y * 0.36, size.y * 0.28]
	for index in 3:
		var pop: float = _pop(index)
		if pop <= 0.0:
			continue
		var scale: float = lerpf(0.4, 1.0, 1.0 - pow(1.0 - pop, 3.0))
		scale *= 1.0 + sin(minf(pop, 1.0) * PI) * 0.06
		draw_set_transform(slots[index], 0.0, Vector2(scale, scale))
		_draw_star(radii[index], index < earned, pop)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _pop(index: int) -> float:
	var start: float = float(index) * 0.16
	return clampf((_reveal - start) / 0.34, 0.0, 1.0)


func _draw_star(radius: float, filled: bool, pop: float) -> void:
	var points: PackedVector2Array = _star_points(radius, radius * 0.42)
	if not filled:
		var dim := ink.lerp(Color(0.55, 0.48, 0.62), 0.72)
		dim.a = 0.38 * pop
		for index in points.size():
			draw_line(points[index], points[(index + 1) % points.size()], dim, maxf(2.2, radius * 0.06), true)
		return
	var glow := ink
	glow.a = 0.28 * pop
	draw_circle(Vector2.ZERO, radius * 1.15, glow)
	var body := ink
	body.a = pop
	draw_colored_polygon(points, body)
	var core: PackedVector2Array = _star_points(radius * 0.48, radius * 0.2)
	var hot := ink.lerp(Color(1.0, 0.97, 0.86), 0.72)
	hot.a = 0.92 * pop
	draw_colored_polygon(core, hot)


func _star_points(outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 10:
		var angle: float = -PI * 0.5 + float(index) * PI / 5.0
		var radius: float = outer if index % 2 == 0 else inner
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
