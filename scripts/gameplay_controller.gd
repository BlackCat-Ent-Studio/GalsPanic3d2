extends Node3D
class_name GameplayController
## Wires together Board, InputHandler, WallPreview, and BuildOperations.

@export_node_path("Node3D") var board_path: NodePath
@export_node_path("Camera3D") var camera_path: NodePath

var board: Board
var camera: Camera3D

var _input_handler: InputHandler
var _wall_preview: WallPreview
var _active_builds: Node3D


func _ready() -> void:
	board = get_node(board_path) as Board
	camera = get_node(camera_path) as Camera3D
	_setup_input_handler()
	_setup_wall_preview()
	_setup_active_builds()


func _setup_input_handler() -> void:
	_input_handler = InputHandler.new()
	_input_handler.name = "InputHandler"
	_input_handler.camera = camera
	_input_handler.board = board
	add_child(_input_handler)
	_input_handler.drag_started.connect(_on_drag_started)
	_input_handler.drag_updated.connect(_on_drag_updated)
	_input_handler.drag_ended.connect(_on_drag_ended)
	_input_handler.drag_cancelled.connect(_on_drag_cancelled)


func _setup_wall_preview() -> void:
	_wall_preview = WallPreview.new()
	_wall_preview.name = "WallPreview"
	add_child(_wall_preview)


func _setup_active_builds() -> void:
	_active_builds = Node3D.new()
	_active_builds.name = "ActiveBuilds"
	add_child(_active_builds)


func _on_drag_started(board_pos: Vector2) -> void:
	_update_preview(board_pos)


func _on_drag_updated(board_pos: Vector2) -> void:
	_update_preview(board_pos)


func _on_drag_ended(board_pos: Vector2) -> void:
	_wall_preview.hide_preview()
	_spawn_build_operation(board_pos)


func _on_drag_cancelled() -> void:
	_wall_preview.hide_preview()


func _update_preview(board_pos: Vector2) -> void:
	var is_valid := board.wall_registry.is_point_in_playable_area(board_pos)
	_wall_preview.show_preview(
		board_pos,
		_input_handler.active_config,
		board.wall_registry,
		is_valid
	)


func _spawn_build_operation(board_pos: Vector2) -> void:
	var op := BuildOperation.new()
	_active_builds.add_child(op)
	op.start(board_pos, _input_handler.active_config, board.wall_registry)
	op.operation_completed.connect(_on_operation_completed)
	op.operation_failed.connect(_on_operation_failed)


func _on_operation_completed(_op: BuildOperation) -> void:
	pass  # Phase 3 will hook territory claiming here


func _on_operation_failed(_op: BuildOperation) -> void:
	pass  # Phase 5 will handle game over logic
