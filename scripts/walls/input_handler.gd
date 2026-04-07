extends Node
class_name InputHandler
## Handles mouse/touch drag-and-drop on XZ ground plane for wall placement.

signal drag_started(board_pos: Vector2)
signal drag_updated(board_pos: Vector2)
signal drag_ended(board_pos: Vector2)
signal drag_cancelled()

@export var camera: Camera3D
@export var board: Board

var _dragging: bool = false
var _drag_position: Vector2 = Vector2.ZERO
var _is_valid_position: bool = false
var _ground_plane := Plane(Vector3.UP, 0.0)
var _enabled: bool = true

## Current generator config (set by UI / picker)
var active_config: Resource


func _ready() -> void:
	active_config = preload("res://resources/generator_cross4.tres")


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag(event.position)
		elif _dragging:
			_end_drag(event.position)
	elif event is InputEventMouseMotion and _dragging:
		_update_drag(event.position)


func _start_drag(screen_pos: Vector2) -> void:
	var board_pos: Variant = _screen_to_board(screen_pos)
	if board_pos == null:
		return
	_dragging = true
	_drag_position = board_pos
	_is_valid_position = _validate_position(board_pos)
	drag_started.emit(board_pos)


func _update_drag(screen_pos: Vector2) -> void:
	var board_pos: Variant = _screen_to_board(screen_pos)
	if board_pos == null:
		_is_valid_position = false
		drag_updated.emit(_drag_position)
		return
	_drag_position = board_pos
	_is_valid_position = _validate_position(board_pos)
	drag_updated.emit(board_pos)


func _end_drag(screen_pos: Vector2) -> void:
	_dragging = false
	var board_pos: Variant = _screen_to_board(screen_pos)
	if board_pos != null:
		_drag_position = board_pos
		_is_valid_position = _validate_position(board_pos)
	if _is_valid_position:
		drag_ended.emit(_drag_position)
	else:
		drag_cancelled.emit()


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
