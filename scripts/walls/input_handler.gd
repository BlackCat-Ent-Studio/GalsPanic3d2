extends Node
class_name InputHandler
## Mouse hover → claw follows. Click → drop block. No dragging needed.

signal cursor_moved(board_pos: Vector2)
signal click_placed(board_pos: Vector2)
signal click_invalid()

@export var camera: Camera3D
@export var board: Board

var _cursor_position: Vector2 = Vector2.ZERO
var _is_valid_position: bool = false
var _ground_plane := Plane(Vector3.UP, 0.0)
var _enabled: bool = true
var _has_cursor: bool = false

## Current generator config (set by UI / picker)
var active_config: Resource


func _ready() -> void:
	active_config = preload("res://resources/generator_cross4.tres")


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return
	# Mouse move (no click needed) → claw follows
	if event is InputEventMouseMotion:
		var board_pos: Variant = _screen_to_board(event.position)
		if board_pos == null:
			return
		_cursor_position = board_pos
		_is_valid_position = _validate_position(board_pos)
		_has_cursor = true
		cursor_moved.emit(board_pos)
	# Click → drop block
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _has_cursor:
			if _is_valid_position:
				click_placed.emit(_cursor_position)
			else:
				click_invalid.emit()


func _screen_to_board(screen_pos: Vector2) -> Variant:
	if camera == null:
		return null
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var hit: Variant = _ground_plane.intersects_ray(from, dir)
	if hit == null:
		return null
	return Board.world_to_board(hit)


func _validate_position(board_pos: Vector2) -> bool:
	if board == null or board.wall_registry == null:
		return false
	return board.wall_registry.is_point_in_playable_area(board_pos)
