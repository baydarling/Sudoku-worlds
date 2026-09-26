class_name RelicGlyph
extends Control
## Line-drawn relic tokens for the Journey shop and play tray.

@export var kind: int = 0
@export var muted: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size.x < 8.0:
		custom_minimum_size = Vector2(64.0, 64.0)


func set_look(new_kind: int, new_muted: bool) -> void:
	kind = new_kind
	muted = new_muted
	queue_redraw()


func _draw() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	var span: float = minf(size.x, size.y)
	var center: Vector2 = size * 0.5
	var ink: Color = _ink()
	var rim: Color = ink
	var well := Color(0.08, 0.05, 0.12, 0.94)
	if muted:
		well.a = 0.5
		rim.a = 0.5
	var radius: float = span * 0.46
	draw_circle(center, radius, well)
	draw_arc(center, radius, 0.0, TAU, 40, rim, maxf(2.0, span * 0.045), true)
	var sheen := Color(1.0, 1.0, 1.0, 0.14 if not muted else 0.06)
	draw_circle(center + Vector2(-radius * 0.28, -radius * 0.3), radius * 0.14, sheen)
	match clampi(kind, 0, 9):
		0:
			_draw_magnet(center, span, ink)
		1:
			_draw_shield(center, span, ink)
		2:
			_draw_coin(center, span, ink)
		3:
			_draw_eye(center, span, ink)
		4:
			_draw_quill(center, span, ink)
		5:
			_draw_hourglass(center, span, ink)
		6:
			_draw_band(center, span, ink)
		7:
			_draw_phoenix(center, span, ink)
		8:
			_draw_heart(center, span, ink)
		9:
			_draw_vial(center, span, ink)


func _ink() -> Color:
	var accents: Array[Color] = [
		Color(1.0, 0.52, 0.38, 1.0),
		Color(0.74, 0.84, 0.96, 1.0),
		Color(0.96, 0.84, 0.38, 1.0),
		Color(0.86, 0.62, 1.0, 1.0),
		Color(0.72, 0.92, 0.78, 1.0),
		Color(0.55, 0.82, 0.96, 1.0),
		Color(1.0, 0.72, 0.28, 1.0),
		Color(1.0, 0.48, 0.32, 1.0),
		Color(1.0, 0.42, 0.48, 1.0),
		Color(0.62, 0.88, 0.96, 1.0),
	]
	var ink: Color = accents[clampi(kind, 0, accents.size() - 1)]
	if muted:
		return ink.lerp(Color(0.42, 0.38, 0.48), 0.5)
	return ink


func _draw_magnet(center: Vector2, span: float, ink: Color) -> void:
	var thick: float = maxf(2.6, span * 0.085)
	var radius: float = span * 0.155
	var base: Vector2 = center + Vector2(0.0, span * 0.07)
	var top_y: float = center.y - span * 0.2
	draw_arc(base, radius, 0.08, PI - 0.08, 22, ink, thick, true)
	var left: Vector2 = base + Vector2(-radius, 0.0)
	var right: Vector2 = base + Vector2(radius, 0.0)
	draw_line(left, Vector2(left.x, top_y), ink, thick, true)
	draw_line(right, Vector2(right.x, top_y), ink, thick, true)
	draw_circle(Vector2(left.x, top_y), thick * 0.72, ink)
	draw_circle(Vector2(right.x, top_y), thick * 0.72, ink)


func _draw_shield(center: Vector2, span: float, ink: Color) -> void:
	var thick: float = maxf(2.2, span * 0.07)
	var w: float = span * 0.195
	var h: float = span * 0.23
	var points := PackedVector2Array([
		center + Vector2(-w, -h * 0.72),
		center + Vector2(w, -h * 0.72),
		center + Vector2(w, h * 0.02),
		center + Vector2(0.0, h),
		center + Vector2(-w, h * 0.02),
	])
	var fill: Color = ink
	fill.a = 0.2 if not muted else 0.1
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, ink, thick, true)
	draw_line(center + Vector2(0.0, -h * 0.48), center + Vector2(0.0, h * 0.38), ink, maxf(1.8, thick * 0.65), true)


func _draw_coin(center: Vector2, span: float, ink: Color) -> void:
	var thick: float = maxf(2.0, span * 0.065)
	var outer: float = span * 0.21
	var fill: Color = ink
	fill.a = 0.18 if not muted else 0.08
	draw_circle(center, outer, fill)
	draw_arc(center, outer, 0.0, TAU, 36, ink, thick, true)
	draw_arc(center, outer * 0.68, 0.0, TAU, 28, ink, maxf(1.6, thick * 0.7), true)
	var tick: float = outer * 0.26
	draw_line(center + Vector2(-tick, 0.0), center + Vector2(tick, 0.0), ink, thick, true)
	draw_line(center + Vector2(0.0, -tick), center + Vector2(0.0, tick), ink, thick, true)


func _draw_eye(center: Vector2, span: float, ink: Color) -> void:
	var thick: float = maxf(2.0, span * 0.065)
	var width: float = span * 0.27
	draw_arc(center + Vector2(0.0, span * 0.105), width, PI + 0.42, TAU - 0.42, 22, ink, thick, true)
	draw_arc(center + Vector2(0.0, -span * 0.105), width, 0.42, PI - 0.42, 22, ink, thick, true)
	draw_circle(center, span * 0.078, ink)
	var glint := Color(1.0, 1.0, 1.0, 0.92 if not muted else 0.32)
	draw_circle(center + Vector2(-span * 0.028, -span * 0.028), span * 0.026, glint)


func _draw_quill(center: Vector2, span: float, ink: Color) -> void:
	var thick: float = maxf(2.0, span * 0.06)
	var from_pt: Vector2 = center + Vector2(-span * 0.2, span * 0.18)
	var to_pt: Vector2 = center + Vector2(span * 0.2, -span * 0.2)
	draw_line(from_pt, to_pt, ink, thick, true)
	var dir: Vector2 = (to_pt - from_pt).normalized()
	var side: Vector2 = Vector2(-dir.y, dir.x)
	for barb in 4:
		var t: float = 0.22 + float(barb) * 0.14
		var along: Vector2 = from_pt.lerp(to_pt, t)
		var len: float = span * (0.09 if barb % 2 == 0 else 0.07)
		draw_line(along, along + side * len - dir * len * 0.35, ink, maxf(1.5, thick * 0.55), true)
		draw_line(along, along - side * len * 0.75 - dir * len * 0.3, ink, maxf(1.5, thick * 0.55), true)
	draw_circle(to_pt, thick * 0.55, ink)


func _draw_hourglass(center: Vector2, span: float, ink: Color) -> void:
	var thick: float = maxf(2.0, span * 0.065)
	var w: float = span * 0.16
	var h: float = span * 0.2
	var top := PackedVector2Array([
		center + Vector2(-w, -h),
		center + Vector2(w, -h),
		center + Vector2(0.0, -span * 0.012),
	])
	var bottom := PackedVector2Array([
		center + Vector2(0.0, span * 0.012),
		center + Vector2(w, h),
		center + Vector2(-w, h),
	])
	var fill: Color = ink
	fill.a = 0.2 if not muted else 0.1
	draw_colored_polygon(top, fill)
	draw_colored_polygon(bottom, fill)
	top.append(top[0])
	bottom.append(bottom[0])
	draw_polyline(top, ink, thick, true)
	draw_polyline(bottom, ink, thick, true)
	draw_line(center + Vector2(-w, -h), center + Vector2(w, -h), ink, thick, true)
	draw_line(center + Vector2(-w, h), center + Vector2(w, h), ink, thick, true)


func _draw_band(center: Vector2, span: float, ink: Color) -> void:
	var thick: float = maxf(2.2, span * 0.07)
	var outer: float = span * 0.21
	var fill: Color = ink
	fill.a = 0.16 if not muted else 0.08
	draw_circle(center, outer, fill)
	draw_arc(center, outer, 0.0, TAU, 36, ink, thick, true)
	draw_arc(center, outer * 0.62, 0.0, TAU, 28, ink, maxf(1.6, thick * 0.65), true)
	var gem := PackedVector2Array([
		center + Vector2(0.0, -span * 0.07),
		center + Vector2(span * 0.055, 0.0),
		center + Vector2(0.0, span * 0.07),
		center + Vector2(-span * 0.055, 0.0),
	])
	draw_colored_polygon(gem, ink)


func _draw_phoenix(center: Vector2, span: float, ink: Color) -> void:
	var thick: float = maxf(2.0, span * 0.06)
	var body := PackedVector2Array([
		center + Vector2(0.0, -span * 0.2),
		center + Vector2(span * 0.05, span * 0.04),
		center + Vector2(0.0, span * 0.2),
		center + Vector2(-span * 0.05, span * 0.04),
	])
	var fill: Color = ink
	fill.a = 0.22 if not muted else 0.1
	draw_colored_polygon(body, fill)
	body.append(body[0])
	draw_polyline(body, ink, thick, true)
	var left := PackedVector2Array([
		center + Vector2(-span * 0.02, -span * 0.02),
		center + Vector2(-span * 0.24, span * 0.02),
		center + Vector2(-span * 0.08, span * 0.08),
	])
	var right := PackedVector2Array([
		center + Vector2(span * 0.02, -span * 0.02),
		center + Vector2(span * 0.24, span * 0.02),
		center + Vector2(span * 0.08, span * 0.08),
	])
	draw_colored_polygon(left, fill)
	draw_colored_polygon(right, fill)
	left.append(left[0])
	right.append(right[0])
	draw_polyline(left, ink, thick, true)
	draw_polyline(right, ink, thick, true)
	draw_circle(center + Vector2(0.0, -span * 0.2), thick * 0.7, ink)


func _draw_heart(center: Vector2, span: float, ink: Color) -> void:
	var thick: float = maxf(2.0, span * 0.06)
	var s: float = span * 0.11
	var left: Vector2 = center + Vector2(-s * 0.85, -s * 0.15)
	var right: Vector2 = center + Vector2(s * 0.85, -s * 0.15)
	var fill: Color = ink
	fill.a = 0.22 if not muted else 0.1
	var body := PackedVector2Array([
		center + Vector2(0.0, s * 1.35),
		center + Vector2(-s * 1.55, -s * 0.05),
		center + Vector2(-s * 0.15, -s * 1.05),
		center + Vector2(s * 0.15, -s * 1.05),
		center + Vector2(s * 1.55, -s * 0.05),
	])
	draw_colored_polygon(body, fill)
	draw_circle(left, s * 0.72, fill)
	draw_circle(right, s * 0.72, fill)
	draw_arc(left, s * 0.72, PI * 0.15, PI * 1.2, 16, ink, thick, true)
	draw_arc(right, s * 0.72, -PI * 0.2, PI * 0.85, 16, ink, thick, true)
	draw_line(center + Vector2(-s * 1.15, s * 0.15), center + Vector2(0.0, s * 1.35), ink, thick, true)
	draw_line(center + Vector2(s * 1.15, s * 0.15), center + Vector2(0.0, s * 1.35), ink, thick, true)


func _draw_vial(center: Vector2, span: float, ink: Color) -> void:
	var thick: float = maxf(2.0, span * 0.06)
	var neck := Rect2(center.x - span * 0.04, center.y - span * 0.22, span * 0.08, span * 0.1)
	var body := PackedVector2Array([
		center + Vector2(-span * 0.09, -span * 0.1),
		center + Vector2(span * 0.09, -span * 0.1),
		center + Vector2(span * 0.12, span * 0.2),
		center + Vector2(-span * 0.12, span * 0.2),
	])
	var fill: Color = ink
	fill.a = 0.2 if not muted else 0.1
	draw_colored_polygon(body, fill)
	body.append(body[0])
	draw_polyline(body, ink, thick, true)
	draw_rect(neck, fill, true)
	draw_rect(neck, ink, false, thick)
	draw_line(center + Vector2(-span * 0.07, span * 0.04), center + Vector2(span * 0.07, span * 0.04), ink, maxf(1.6, thick * 0.7), true)
