@tool
extends Control
## Visual board grid for the level editor. Click to place/remove fireballs.

signal fireball_placed(board_pos: Vector2, fireball_type: String)
signal fireball_removed(index: int)

const BOARD_MIN := -10.0
const BOARD_MAX := 10.0
const BOARD_SIZE := 20.0
const GRID_CELLS := 20

var fireballs: Array = []  # [{type, position, speed, radius}]
var active_tool: String = "red"  # "red", "yellow", "white", "erase"
var _preview_size := Vector2(280, 280)

var _type_colors := {
	"red": Color(1.0, 0.2, 0.15),
	"yellow": Color(1.0, 0.85, 0.1),
	"white": Color(0.9, 0.9, 1.0),
	"boss_tank": Color(0.8, 0.1, 0.9),
	"boss_ghost": Color(0.3, 0.9, 0.7),
}
var _boss_types := ["boss_tank", "boss_ghost"]


func _init() -> void:
	custom_minimum_size = _preview_size


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, _preview_size)
	# Background
	draw_rect(rect, Color(0.12, 0.14, 0.18))
	# Grid lines
	var cell := _preview_size / GRID_CELLS
	for i in GRID_CELLS + 1:
		var x := cell.x * i
		var y := cell.y * i
		draw_line(Vector2(x, 0), Vector2(x, _preview_size.y), Color(0.25, 0.25, 0.3), 1.0)
		draw_line(Vector2(0, y), Vector2(_preview_size.x, y), Color(0.25, 0.25, 0.3), 1.0)
	# Border
	draw_rect(rect, Color(0.4, 0.4, 0.5), false, 2.0)
	# Fireballs
	for i in fireballs.size():
		var fb: Dictionary = fireballs[i]
		var screen_pos := _board_to_screen(fb["position"])
		var color: Color = _type_colors.get(fb["type"], Color.WHITE)
		var fb_type: String = fb["type"]
		var is_boss: bool = fb_type.begins_with("boss")
		var circle_radius := 14.0 if is_boss else 8.0
		draw_circle(screen_pos, circle_radius, color)
		if is_boss:
			draw_arc(screen_pos, circle_radius + 2, 0, TAU, 24, Color.WHITE, 1.5)
		# Label
		var label_char: String = fb["type"].substr(0, 1).to_upper()
		draw_string(ThemeDB.fallback_font, screen_pos + Vector2(-4, 4), label_char,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.BLACK)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = event.position
		if Rect2(Vector2.ZERO, _preview_size).has_point(pos):
			var board_pos := _screen_to_board(pos)
			if active_tool == "erase":
				_try_erase_at(pos)
			else:
				fireball_placed.emit(board_pos, active_tool)
				queue_redraw()


func _try_erase_at(screen_pos: Vector2) -> void:
	for i in range(fireballs.size() - 1, -1, -1):
		var fb_screen := _board_to_screen(fireballs[i]["position"])
		if screen_pos.distance_to(fb_screen) < 12.0:
			fireball_removed.emit(i)
			queue_redraw()
			return


func _board_to_screen(board_pos: Vector2) -> Vector2:
	var norm := (board_pos - Vector2(BOARD_MIN, BOARD_MIN)) / BOARD_SIZE
	return norm * _preview_size


func _screen_to_board(screen_pos: Vector2) -> Vector2:
	var norm := screen_pos / _preview_size
	return Vector2(BOARD_MIN, BOARD_MIN) + norm * BOARD_SIZE


func set_fireballs(data: Array) -> void:
	fireballs = data
	queue_redraw()
