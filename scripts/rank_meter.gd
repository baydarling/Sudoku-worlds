class_name RankMeter
extends Control
## Journey rank. Newly earned stars travel into the bar, and a full bar is the next rank.

var rank_name: String = "Wanderer"
var fill: int = 0
var need: int = 9

var _names: Array[String] = []
var _marks: PackedInt32Array = PackedInt32Array()
var _shown: float = 0.0
var _target: float = 0.0
var _ratio: float = 0.0
var _delay: float = 0.0
var _hold: float = 0.0
var _hold_full: bool = false
var _finish_after_hold: bool = false
var _running: bool = false
var _motes: PackedFloat32Array = PackedFloat32Array()
var _mote_x: PackedFloat32Array = PackedFloat32Array()

const FILL_RATE: float = 5.5
const HOLD_TIME: float = 0.28
const MOTE_TIME: float = 0.48


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func set_rank(next_name: String, next_fill: int, next_need: int) -> void:
	rank_name = next_name
	fill = maxi(0, next_fill)
	need = maxi(1, next_need)
	_ratio = clampf(float(fill) / float(need), 0.0, 1.0)
	_running = false
	_hold_full = false
	_motes = PackedFloat32Array()
	set_process(false)
	queue_redraw()


func show_total(total: int, names: Array[String], marks: PackedInt32Array, from_total: int = -1, delay: float = 0.0) -> void:
	var safe_total: int = maxi(0, total)
	if from_total < 0 and _running and absf(_target - float(safe_total)) < 0.5:
		return
	_names = names
	_marks = marks
	_target = float(safe_total)
	_hold = 0.0
	_hold_full = false
	_finish_after_hold = false
	_motes = PackedFloat32Array()
	_mote_x = PackedFloat32Array()
	if from_total >= 0 and from_total < safe_total:
		_shown = float(from_total)
		_delay = maxf(0.0, delay)
		_running = true
		var gained: int = clampi(safe_total - from_total, 1, 3)
		for index in gained:
			_motes.append(-0.16 * float(index))
			if gained == 1:
				_mote_x.append(0.5)
			else:
				_mote_x.append(lerpf(0.28, 0.72, float(index) / float(gained - 1)))
		set_process(true)
	else:
		_shown = _target
		_delay = 0.0
		_running = false
		set_process(false)
	_sync()
	queue_redraw()


func _process(delta: float) -> void:
	if _delay > 0.0:
		_delay = maxf(0.0, _delay - delta)
		_sync()
		queue_redraw()
		return
	if _hold > 0.0:
		_hold = maxf(0.0, _hold - delta)
		_advance_motes(delta)
		if _hold <= 0.0:
			_hold_full = false
			if _finish_after_hold:
				_shown = _target
				_finish_after_hold = false
		_sync()
		queue_redraw()
		if _hold <= 0.0 and _shown >= _target and _motes_done():
			_finish()
		return
	if _shown < _target:
		var before_index: int = _index_of(_shown)
		_shown = minf(_target, _shown + delta * FILL_RATE)
		var after_index: int = _index_of(_shown)
		if after_index > before_index and after_index < _marks.size():
			_shown = float(_marks[after_index])
			_hold = HOLD_TIME
			_hold_full = true
			_finish_after_hold = _shown >= _target - 0.001
	_advance_motes(delta)
	_sync()
	queue_redraw()
	if _shown >= _target and _hold <= 0.0 and _motes_done():
		_finish()


func _advance_motes(delta: float) -> void:
	for index in _motes.size():
		if _motes[index] < 1.2:
			_motes[index] += delta / MOTE_TIME


func _motes_done() -> bool:
	for age in _motes:
		if age < 1.05:
			return false
	return true


func _finish() -> void:
	_shown = _target
	_running = false
	_hold = 0.0
	_hold_full = false
	_finish_after_hold = false
	_motes = PackedFloat32Array()
	set_process(false)
	_sync()
	queue_redraw()


func _index_of(stars: float) -> int:
	if _names.is_empty() or _marks.is_empty():
		return 0
	var whole: int = int(floor(maxf(0.0, stars)))
	var index: int = 0
	for step in _marks.size():
		if whole >= _marks[step]:
			index = step
	return clampi(index, 0, _names.size() - 1)


func _span(index: int) -> int:
	if _marks.is_empty():
		return 1
	var safe: int = clampi(index, 0, _marks.size() - 1)
	if safe >= _marks.size() - 1:
		var previous: int = _marks[safe - 1] if safe > 0 else 0
		return maxi(1, _marks[safe] - previous)
	return maxi(1, _marks[safe + 1] - _marks[safe])


func _sync() -> void:
	if _names.is_empty():
		_ratio = 0.0
		return
	if _hold_full:
		var completed: int = maxi(0, _index_of(_shown) - 1)
		rank_name = _names[completed]
		fill = _span(completed)
		need = fill
		_ratio = 1.0
		return
	var index: int = _index_of(_shown)
	rank_name = _names[index]
	var span: int = _span(index)
	if index >= _names.size() - 1:
		fill = span
		need = span
		_ratio = 1.0
		return
	var into: float = _shown - float(_marks[index])
	fill = clampi(int(floor(into)), 0, span)
	need = span
	_ratio = clampf(into / float(span), 0.0, 1.0)


func _draw() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	var font: Font = get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font
	if font == null:
		return
	var title_size: int = 18
	var title: String = rank_name.to_upper()
	var count: String = "%d/%d" % [mini(fill, need), need]
	var line: String = "%s  ·  %s" % [title, count]
	var line_width: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, title_size).x
	var ink := Color(0.93, 0.78, 0.42) if _hold_full else Color(0.93, 0.94, 0.98)
	draw_string(font, Vector2((size.x - line_width) * 0.5, 16.0), line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, title_size, ink)
	var bar_width: float = minf(168.0, size.x * 0.46)
	var bar := Rect2((size.x - bar_width) * 0.5, 26.0, bar_width, 3.0)
	draw_rect(bar, Color(0.93, 0.78, 0.42, 0.28), true)
	if _ratio > 0.0:
		var fill_rect := Rect2(bar.position, Vector2(bar.size.x * _ratio, bar.size.y))
		draw_rect(fill_rect, Color(0.93, 0.78, 0.42), true)
	var tip := Vector2(bar.position.x + bar.size.x * _ratio, bar.position.y + bar.size.y * 0.5)
	for index in _motes.size():
		var age: float = _motes[index]
		if age <= 0.0 or age >= 1.0:
			continue
		var start := Vector2(size.x * _mote_x[index], -34.0)
		var point: Vector2 = start.lerp(tip, 1.0 - pow(1.0 - age, 3.0))
		var alpha: float = sin(clampf(age, 0.0, 1.0) * PI)
		_draw_star(point, lerpf(11.0, 5.0, age), Color(1.0, 0.86, 0.46, alpha))


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 10:
		var angle: float = -PI * 0.5 + float(index) * PI / 5.0
		var arm: float = radius if index % 2 == 0 else radius * 0.42
		points.append(center + Vector2(cos(angle), sin(angle)) * arm)
	draw_colored_polygon(points, color)
