class_name SandCache
extends Control
## Desert treasure. The closed chest sits on the cell until that cell is solved, then the lid opens.

const CHEST: Texture2D = preload("res://art/desert_chest.png")
## Pixel row where the lid ends in art/desert_chest.png. The body, including the keyhole, starts here.
const LID_PIXELS: float = 104.0
const OPEN_TIME: float = 0.42
const HOLD_TIME: float = 0.28
const FADE_TIME: float = 0.36

var cell_index: int = -1
var bounty: int = 0
var resolved: bool = false

var _time: float = 0.0
var _open: float = 0.0
var _hold: float = 0.0
var _fade: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	clip_contents = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_process(true)


func set_resolved(value: bool, animate: bool = true) -> void:
	if resolved == value:
		return
	resolved = value
	_open = 0.0
	_hold = 0.0
	_fade = 0.0
	modulate = Color.WHITE
	z_index = 7
	if resolved and not animate:
		visible = false
		set_process(false)
		return
	visible = true
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if resolved:
		z_index = 16
		if _open < 1.0:
			_open = minf(1.0, _open + delta / OPEN_TIME)
		elif _hold < HOLD_TIME:
			_hold += delta
		else:
			_fade = minf(1.0, _fade + delta / FADE_TIME)
			modulate.a = 1.0 - _fade
			if _fade >= 1.0:
				visible = false
				z_index = 7
				set_process(false)
				return
	queue_redraw()


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0 or CHEST == null:
		return
	var tex_size := CHEST.get_size()
	if tex_size.x < 1.0 or tex_size.y < 1.0:
		return
	var aspect: float = tex_size.x / tex_size.y
	var width: float = size.x * 0.98
	var height: float = width / aspect
	if height > size.y * 0.9:
		height = size.y * 0.9
		width = height * aspect
	var bob: float = 0.0
	if not resolved:
		bob = sin(_time * 2.3 + float(cell_index) * 0.37) * size.y * 0.012
	var origin := Vector2((size.x - width) * 0.5, (size.y - height) * 0.55 + bob)
	var lid_ratio: float = clampf(LID_PIXELS / tex_size.y, 0.05, 0.9)
	var lid_h: float = height * lid_ratio
	var body_origin := origin + Vector2(0.0, lid_h)
	var body_size := Vector2(width, height - lid_h)
	var open_amt: float = _ease_out(_open)

	_draw_shadow(origin, width, height)
	var body_src := Rect2(0.0, LID_PIXELS, tex_size.x, tex_size.y - LID_PIXELS)
	draw_texture_rect_region(CHEST, Rect2(body_origin, body_size), body_src)
	# The hinge is the back edge. The lid shortens straight up; it does not swing sideways.
	var lid_scale_y: float = lerpf(1.0, 0.18, open_amt)
	var lid_bottom: float = origin.y + lid_h * lid_scale_y
	var back: float = clampf((open_amt - 0.34) / 0.66, 0.0, 1.0)
	if back > 0.02:
		_draw_lid_arch(origin.x + width * 0.5, lid_bottom, width, lid_h, back)
	if open_amt > 0.12:
		_draw_interior(origin.x, width, lid_bottom, body_origin, body_size, open_amt)
	var outside: float = 1.0 - clampf((open_amt - 0.4) / 0.45, 0.0, 1.0)
	if outside > 0.02:
		var lid_src := Rect2(0.0, 0.0, tex_size.x, LID_PIXELS)
		draw_set_transform(Vector2(origin.x + width * 0.5, origin.y), 0.0, Vector2(1.0, lid_scale_y))
		draw_texture_rect_region(CHEST, Rect2(-width * 0.5, 0.0, width, lid_h), lid_src, Color(1.0, 1.0, 1.0, outside))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_shadow(origin: Vector2, width: float, height: float) -> void:
	var shadow := Color(0.32, 0.16, 0.04, 0.32)
	var center := origin + Vector2(width * 0.5, height * 0.9)
	draw_set_transform(center, 0.0, Vector2(width * 0.34, maxf(2.0, height * 0.07)))
	draw_circle(Vector2.ZERO, 1.0, shadow)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The inside of the lid, standing up behind the chest.
func _draw_lid_arch(mid_x: float, hinge_y: float, width: float, lid_h: float, back: float) -> void:
	var rise: float = lid_h * 1.05 * back
	var half: float = width * 0.4
	var gold := Color(0.93, 0.73, 0.19, back)
	var outer := PackedVector2Array([
		Vector2(mid_x - half, hinge_y),
		Vector2(mid_x - half * 0.86, hinge_y - rise * 0.72),
		Vector2(mid_x, hinge_y - rise),
		Vector2(mid_x + half * 0.86, hinge_y - rise * 0.72),
		Vector2(mid_x + half, hinge_y),
	])
	draw_colored_polygon(outer, gold)
	var inner := PackedVector2Array([
		Vector2(mid_x - half * 0.72, hinge_y - rise * 0.04),
		Vector2(mid_x - half * 0.58, hinge_y - rise * 0.62),
		Vector2(mid_x, hinge_y - rise * 0.82),
		Vector2(mid_x + half * 0.58, hinge_y - rise * 0.62),
		Vector2(mid_x + half * 0.72, hinge_y - rise * 0.04),
	])
	draw_colored_polygon(inner, Color(0.29, 0.15, 0.06, back))
	var clasp := Vector2(maxf(1.5, width * 0.035), maxf(2.0, rise * 0.16))
	draw_rect(Rect2(mid_x - clasp.x, hinge_y - rise * 0.7, clasp.x * 2.0, clasp.y), Color(0.58, 0.62, 0.66, back), true)


func _draw_interior(origin_x: float, width: float, lid_bottom: float, body_origin: Vector2, body_size: Vector2, open_amt: float) -> void:
	var alpha: float = clampf((open_amt - 0.18) / 0.4, 0.0, 1.0)
	if alpha <= 0.0:
		return
	var gap_bottom: float = body_origin.y + body_size.y * 0.08
	if gap_bottom <= lid_bottom + 1.5:
		return
	var mouth := Rect2(origin_x + width * 0.16, lid_bottom, width * 0.68, gap_bottom - lid_bottom)
	draw_rect(mouth, Color(0.16, 0.08, 0.03, alpha), true)
	var rows: int = 3 if open_amt > 0.72 else 2
	var radius: float = maxf(1.2, mouth.size.y * 0.11)
	var mid_x: float = mouth.position.x + mouth.size.x * 0.5
	for row in rows:
		var along: float = float(row) / float(rows)
		var coin_y: float = lerpf(mouth.end.y - radius, mouth.position.y + radius * 1.4, along)
		var span: int = 3 - row
		for slot in range(-span, span + 1):
			var center := Vector2(mid_x + float(slot) * radius * 1.85, coin_y)
			draw_circle(center, radius, Color(0.9, 0.67, 0.11, alpha))
			draw_circle(center + Vector2(-radius * 0.2, -radius * 0.22), radius * 0.42, Color(1.0, 0.9, 0.5, alpha))


func _ease_out(amount: float) -> float:
	var t: float = clampf(amount, 0.0, 1.0)
	return sin(t * PI * 0.5)
