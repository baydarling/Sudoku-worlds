class_name FooterIcon
extends Control
## Simple line icons for the home footer.

enum Kind { SETTINGS, PROFILE, BOARD, QUIT }

@export var kind: Kind = Kind.SETTINGS


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(36.0, 36.0)


func _draw() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	var ink := Color(0.88, 0.9, 0.96, 1.0)
	var center: Vector2 = size * 0.5
	match kind:
		Kind.SETTINGS:
			_draw_settings(center, ink)
		Kind.PROFILE:
			_draw_profile(center, ink)
		Kind.BOARD:
			_draw_board(center, ink)
		Kind.QUIT:
			_draw_quit(center, ink)


func _draw_settings(center: Vector2, ink: Color) -> void:
	draw_arc(center, 8.0, 0.0, TAU, 32, ink, 2.2, true)
	draw_circle(center, 3.2, ink)
	for spoke in 6:
		var angle: float = float(spoke) * TAU / 6.0
		var inner: Vector2 = center + Vector2(cos(angle), sin(angle)) * 11.0
		var outer: Vector2 = center + Vector2(cos(angle), sin(angle)) * 15.5
		draw_line(inner, outer, ink, 2.4, true)


func _draw_profile(center: Vector2, ink: Color) -> void:
	draw_arc(center + Vector2(0.0, -5.0), 6.5, 0.0, TAU, 28, ink, 2.2, true)
	draw_arc(center + Vector2(0.0, 14.0), 12.0, PI * 1.12, PI * 1.88, 20, ink, 2.2, true)


func _draw_board(center: Vector2, ink: Color) -> void:
	var base_y: float = center.y + 12.0
	var bars: Array[float] = [11.0, 20.0, 15.0]
	var x: float = center.x - 14.0
	for height in bars:
		draw_rect(Rect2(x, base_y - height, 8.0, height), ink, true)
		x += 11.0


func _draw_quit(center: Vector2, ink: Color) -> void:
	draw_arc(center + Vector2(0.0, 2.0), 10.0, PI * 0.28, TAU - PI * 0.28, 28, ink, 2.2, true)
	draw_line(center + Vector2(0.0, -12.0), center + Vector2(0.0, 1.0), ink, 2.4, true)
