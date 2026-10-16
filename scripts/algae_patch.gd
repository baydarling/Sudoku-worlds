class_name AlgaePatch
extends TextureRect
## Seaweed overlay for Water-world cells. Three taps rip it off.

signal cleaned(cell_index: int)
signal tapped(cell_index: int)
signal splashed(cell_index: int)

const TAP_NEED: int = 3
const RIP_TIME: float = 0.46
const SHARD_COLS: int = 3
const SHARD_ROWS: int = 2

var cell_index: int = -1

var _taps: int = 0
var _spent: bool = false
var _ripping: bool = false
var _rip: float = 0.0
var _pulse: float = 1.0
var _shards: Array[Dictionary] = []
var _shard_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP
	clip_contents = true
	texture = null
	modulate = Color.WHITE


func _draw() -> void:
	if size.x < 2.0 or size.y < 2.0:
		return
	_ensure_shards()
	var spread: float = 0.0
	if _taps == 1:
		spread = 0.055
	elif _taps >= 2:
		spread = 0.13
	var peel: float = _rip if _ripping else 0.0
	for shard in _shards:
		_draw_shard(shard, spread, peel)
	if _taps >= 1 and not _ripping:
		_draw_cracks(spread)


func _ensure_shards() -> void:
	if not _shards.is_empty() and _shard_size.is_equal_approx(size):
		return
	_shards.clear()
	_shard_size = size
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(cell_index) + 9176
	var cols: int = SHARD_COLS
	var rows: int = SHARD_ROWS
	var grid: Array[Vector2] = []
	for row in rows + 1:
		for col in cols + 1:
			var u: float = float(col) / float(cols)
			var v: float = float(row) / float(rows)
			var jitter_x: float = 0.0
			var jitter_y: float = 0.0
			if col > 0 and col < cols:
				jitter_x = rng.randf_range(-0.09, 0.09)
			if row > 0 and row < rows:
				jitter_y = rng.randf_range(-0.1, 0.1)
			grid.append(Vector2(clampf(u + jitter_x, 0.0, 1.0) * size.x, clampf(v + jitter_y, 0.0, 1.0) * size.y))
	var mid: Vector2 = size * 0.5
	for row in rows:
		for col in cols:
			var i00: int = row * (cols + 1) + col
			var i10: int = i00 + 1
			var i01: int = i00 + cols + 1
			var i11: int = i01 + 1
			var poly: PackedVector2Array = PackedVector2Array()
			poly.append_array(_jagged_edge(grid[i00], grid[i10], rng))
			poly.append_array(_jagged_edge(grid[i10], grid[i11], rng))
			poly.append_array(_jagged_edge(grid[i11], grid[i01], rng))
			poly.append_array(_jagged_edge(grid[i01], grid[i00], rng))
			var center: Vector2 = _poly_center(poly)
			var away: Vector2 = center - mid
			if away.length_squared() < 4.0:
				away = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
			away = away.normalized()
			var tangent := Vector2(-away.y, away.x)
			var fly: Vector2 = away * rng.randf_range(0.72, 1.18) + tangent * rng.randf_range(-0.45, 0.45)
			_shards.append({
				"points": poly,
				"center": center,
				"fly": fly.normalized(),
				"spin": rng.randf_range(-1.2, 1.2),
				"delay": rng.randf_range(0.0, 0.22),
				"shade": rng.randf_range(0.0, 1.0),
			})


func _jagged_edge(from_pt: Vector2, to_pt: Vector2, rng: RandomNumberGenerator) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.append(from_pt)
	var span: Vector2 = to_pt - from_pt
	var normal: Vector2 = Vector2(-span.y, span.x)
	if normal.length_squared() > 0.01:
		normal = normal.normalized()
	var mids: int = 2
	for step in mids:
		var t: float = float(step + 1) / float(mids + 1)
		var jag: float = rng.randf_range(-1.0, 1.0) * minf(size.x, size.y) * 0.055
		points.append(from_pt.lerp(to_pt, t) + normal * jag)
	return points


func _draw_shard(shard: Dictionary, spread: float, peel: float) -> void:
	var points: PackedVector2Array = shard["points"]
	var center: Vector2 = shard["center"]
	var delay: float = shard["delay"]
	var local_peel: float = 0.0
	if peel > 0.0:
		local_peel = clampf((peel - delay) / maxf(0.08, 1.0 - delay), 0.0, 1.0)
	var ease: float = local_peel * local_peel
	var shift: Vector2 = shard["fly"] * minf(size.x, size.y) * (spread + 0.82 * ease)
	var rot: float = shard["spin"] * ease
	var fade: float = 1.0 - ease * 0.55
	var scale_amt: float = 1.0 - ease * 0.28
	var cosine: float = cos(rot)
	var sine: float = sin(rot)
	var drawn := PackedVector2Array()
	for point in points:
		var local: Vector2 = (point - center) * scale_amt
		var turned := Vector2(local.x * cosine - local.y * sine, local.x * sine + local.y * cosine)
		drawn.append(turned + center + shift)
	if drawn.size() < 3:
		return
	var shade: float = shard["shade"]
	var fill := Color(0.06 + shade * 0.05, 0.4 + shade * 0.14, 0.16 + shade * 0.06, fade)
	var edge := Color(0.03, 0.22, 0.08, fade)
	var shine := Color(0.3, 0.76, 0.34, fade * 0.85)
	draw_colored_polygon(drawn, fill)
	draw_polyline(drawn, edge, maxf(1.8, size.x * 0.03), true)
	draw_circle(center + shift, size.x * 0.055 * fade, shine)


func _draw_cracks(spread: float) -> void:
	var ink := Color(0.02, 0.07, 0.03, 0.92)
	var width: float = maxf(2.2, size.x * 0.04 + spread * size.x * 0.35)
	for shard in _shards:
		var points: PackedVector2Array = shard["points"]
		if points.size() < 2:
			continue
		var outline := PackedVector2Array(points)
		outline.append(points[0])
		draw_polyline(outline, ink, width, true)


func _poly_center(points: PackedVector2Array) -> Vector2:
	var total := Vector2.ZERO
	for point in points:
		total += point
	if points.is_empty():
		return size * 0.5
	return total / float(points.size())


func _process(delta: float) -> void:
	if _ripping:
		_rip = minf(_rip + delta / RIP_TIME, 1.0)
		modulate = Color(1.0, 1.0, 1.0, 1.0 - _rip * 0.2)
		queue_redraw()
		if _rip >= 1.0:
			cleaned.emit(cell_index)
			queue_free()
		return
	if _pulse > 1.001:
		_pulse = lerpf(_pulse, 1.0, minf(delta * 14.0, 1.0))
		scale = Vector2(_pulse, 2.0 - _pulse)
		pivot_offset = size * 0.5
	else:
		scale = Vector2.ONE
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if _spent:
		return
	# Phones also emit ScreenTouch. Count emulated mouse only so 3 taps stay 3.
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		if button.pressed:
			_register_tap()
		accept_event()


func _register_tap() -> void:
	if _spent:
		return
	_taps += 1
	_pulse = 1.08
	pivot_offset = size * 0.5
	queue_redraw()
	_spawn_burst(10 if _taps < TAP_NEED else 22)
	if _taps >= TAP_NEED:
		_begin_rip()
		return
	tapped.emit(cell_index)


func _begin_rip() -> void:
	_spent = true
	_ripping = true
	_rip = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	splashed.emit(cell_index)


func _spawn_burst(amount: int) -> void:
	var host: Node = get_parent()
	if host == null:
		return
	var bits := CPUParticles2D.new()
	bits.name = "AlgaeBurst"
	bits.one_shot = true
	bits.explosiveness = 1.0
	bits.amount = amount
	bits.lifetime = 0.4
	bits.local_coords = false
	bits.emitting = false
	bits.direction = Vector2(0.0, -1.0)
	bits.spread = 180.0
	bits.gravity = Vector2(0.0, 120.0)
	bits.initial_velocity_min = 24.0
	bits.initial_velocity_max = 110.0
	bits.scale_amount_min = 1.3
	bits.scale_amount_max = 3.6
	bits.color = Color(0.45, 0.9, 0.42, 0.95)
	host.add_child(bits)
	bits.position = position + size * 0.5
	bits.emitting = true
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.create_timer(0.55).timeout.connect(bits.queue_free)
