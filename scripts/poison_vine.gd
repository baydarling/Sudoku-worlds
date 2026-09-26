class_name PoisonVine
extends Control
## Thorny wreath for a Forest poison cell. Taps pass through to the board.

var cell_index: int = -1
var bounty: int = 0

var _resolved: bool = false
var _wilt: float = 0.0
var _pulse: float = 0.0
var _stems: Array[PackedVector2Array] = []
var _thorns: Array[PackedVector2Array] = []
var _cached: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	clip_contents = true
	set_process(true)


func set_resolved(resolved: bool) -> void:
	if resolved == _resolved:
		return
	_resolved = resolved
	if resolved:
		set_process(true)
		return
	visible = true
	_wilt = 0.0
	modulate = Color.WHITE
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree() and not _resolved:
		return
	_pulse += delta
	if _resolved:
		_wilt = minf(_wilt + delta * 3.6, 1.0)
		modulate = Color(0.62, 0.92, 0.38, 1.0 - _wilt)
		if _wilt >= 1.0:
			visible = false
			set_process(false)
			return
	queue_redraw()


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	_ensure_paths()
	var breathe: float = 0.5 + 0.5 * sin(_pulse * 2.1 + float(cell_index) * 0.37)
	var fade: float = 1.0 - _wilt
	var wash := Color(0.08, 0.32, 0.1, (0.34 + 0.1 * breathe) * fade)
	var rim: float = minf(size.x, size.y) * 0.22
	draw_rect(Rect2(0.0, 0.0, size.x, rim), wash, true)
	draw_rect(Rect2(0.0, size.y - rim, size.x, rim), wash, true)
	draw_rect(Rect2(0.0, rim, rim, size.y - rim * 2.0), wash, true)
	draw_rect(Rect2(size.x - rim, rim, rim, size.y - rim * 2.0), wash, true)
	var stem := Color(0.1, 0.38, 0.12, 0.96 * fade)
	var lit := Color(0.32, 0.78, 0.24, (0.72 + 0.22 * breathe) * fade)
	var thorn := Color(0.62, 0.92, 0.3, 0.95 * fade)
	var width: float = maxf(2.2, minf(size.x, size.y) * 0.055) * (1.0 - _wilt * 0.45)
	for path in _stems:
		if path.size() < 2:
			continue
		draw_polyline(path, stem, width * 2.2, true)
		draw_polyline(path, lit, width, true)
	for spike in _thorns:
		if spike.size() < 3:
			continue
		draw_colored_polygon(spike, thorn)
		draw_polyline(spike, Color(0.16, 0.34, 0.1, 0.85 * fade), 1.1, true)
	if bounty > 0 and fade > 0.12:
		_draw_bounty(fade)


func _draw_bounty(fade: float) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var text: String = "+%d" % bounty
	var font_size: int = maxi(11, int(minf(size.x, size.y) * 0.22))
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var draw_at := Vector2((size.x - text_size.x) * 0.5, size.y - minf(size.y, size.x) * 0.07)
	var gold := Color(1.0, 0.86, 0.38, 0.95 * fade)
	var shadow := Color(0.02, 0.08, 0.02, 0.7 * fade)
	draw_string(font, draw_at + Vector2(0.0, 1.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, shadow)
	draw_string(font, draw_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, gold)


func _ensure_paths() -> void:
	if not _stems.is_empty() and _cached.is_equal_approx(size):
		return
	_stems.clear()
	_thorns.clear()
	_cached = size
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(cell_index) * 7919 + 17
	var pad: float = minf(size.x, size.y) * 0.07
	var depth: float = minf(size.x, size.y) * 0.2
	_add_edge(_edge_points(rng, Vector2(pad, pad), Vector2(size.x - pad, pad), Vector2(0.0, 1.0), depth), rng)
	_add_edge(_edge_points(rng, Vector2(size.x - pad, pad), Vector2(size.x - pad, size.y - pad), Vector2(-1.0, 0.0), depth), rng)
	_add_edge(_edge_points(rng, Vector2(size.x - pad, size.y - pad), Vector2(pad, size.y - pad), Vector2(0.0, -1.0), depth), rng)
	_add_edge(_edge_points(rng, Vector2(pad, size.y - pad), Vector2(pad, pad), Vector2(1.0, 0.0), depth), rng)
	_add_tendril(rng, Vector2(pad, pad * 2.2), Vector2(size.x * 0.42, depth * 0.9), Vector2(size.x * 0.18, size.y * 0.38))
	_add_tendril(rng, Vector2(size.x - pad, size.y - pad * 2.0), Vector2(size.x * 0.58, size.y - depth), Vector2(size.x * 0.78, size.y * 0.62))


func _edge_points(rng: RandomNumberGenerator, from_pt: Vector2, to_pt: Vector2, inward: Vector2, depth: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps: int = 8
	for step in range(steps + 1):
		var t: float = float(step) / float(steps)
		var along: Vector2 = from_pt.lerp(to_pt, t)
		var wave: float = sin(t * TAU * rng.randf_range(1.1, 1.7) + rng.randf() * 0.8)
		var bulge: float = depth * (0.35 + 0.65 * absf(wave)) * rng.randf_range(0.72, 1.12)
		if step == 0 or step == steps:
			bulge *= 0.25
		points.append(along + inward * bulge)
	return points


func _add_edge(points: PackedVector2Array, rng: RandomNumberGenerator) -> void:
	if points.size() < 2:
		return
	_stems.append(points)
	var index: int = 1
	while index < points.size() - 1:
		if rng.randf() < 0.72:
			_add_thorn(points[index - 1], points[index], points[index + 1], rng)
		index += 1 + rng.randi_range(0, 1)


func _add_tendril(rng: RandomNumberGenerator, from_pt: Vector2, control: Vector2, to_pt: Vector2) -> void:
	var points := PackedVector2Array()
	var steps: int = 7
	for step in range(steps + 1):
		var t: float = float(step) / float(steps)
		var jitter: Vector2 = Vector2(rng.randf_range(-1.4, 1.4), rng.randf_range(-1.4, 1.4))
		points.append(_quad(from_pt, control, to_pt, t) + jitter)
	_stems.append(points)
	if points.size() >= 3:
		_add_thorn(points[2], points[3] if points.size() > 3 else points[2], points[points.size() - 2], rng)
		_add_thorn(points[points.size() - 3], points[points.size() - 2], points[points.size() - 1], rng)


func _add_thorn(prev_pt: Vector2, at_pt: Vector2, next_pt: Vector2, rng: RandomNumberGenerator) -> void:
	var tangent: Vector2 = (next_pt - prev_pt).normalized()
	if tangent.length_squared() < 0.0001:
		return
	var side: Vector2 = Vector2(-tangent.y, tangent.x)
	if rng.randf() < 0.5:
		side = -side
	var length: float = minf(size.x, size.y) * rng.randf_range(0.07, 0.13)
	var base: float = length * 0.28
	var spike := PackedVector2Array()
	spike.append(at_pt - tangent * base)
	spike.append(at_pt + side * length)
	spike.append(at_pt + tangent * base)
	_thorns.append(spike)


func _quad(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	return a * (u * u) + b * (2.0 * u * t) + c * (t * t)
