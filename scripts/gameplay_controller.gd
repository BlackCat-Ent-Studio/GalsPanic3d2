extends Node3D
class_name GameplayController
## Wires together Board, InputHandler, WallPreview, BuildOperations, and Fireballs.

@export_node_path("Node3D") var board_path: NodePath
@export_node_path("Camera3D") var camera_path: NodePath

var board: Board
var camera: Camera3D

var _input_handler: InputHandler
var _wall_preview: WallPreview
var _active_builds: Node3D
var _fireball_manager: FireballManager


func _ready() -> void:
	board = get_node(board_path) as Board
	camera = get_node(camera_path) as Camera3D
	_setup_input_handler()
	_setup_wall_preview()
	_setup_active_builds()
	_setup_fireball_manager()
	# Spawn default fireballs for testing (Phase 5 will use level config)
	_spawn_test_fireballs()


func _physics_process(_delta: float) -> void:
	# Check fireball-arm collisions each physics frame
	if _fireball_manager and _active_builds:
		_fireball_manager.check_arm_collisions(_active_builds)


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


func _setup_fireball_manager() -> void:
	_fireball_manager = FireballManager.new()
	_fireball_manager.name = "Fireballs"
	add_child(_fireball_manager)
	_fireball_manager.setup(board.wall_registry)


func _spawn_test_fireballs() -> void:
	var red_config := preload("res://resources/fireball_red.tres")
	var spawn_entries: Array = [
		{"config": red_config, "count": 2}
	]
	_fireball_manager.spawn_fireballs(spawn_entries, 1)


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


func _on_operation_completed(op: BuildOperation) -> void:
	var endpoints := PackedVector2Array()
	for arm: BuildArm in op.completed_arms:
		endpoints.append(arm.end_pos)

	# Get live fireball positions for Qix rule
	var fireball_positions := _fireball_manager.get_fireball_positions()

	# Claim territory via star-split + Qix rule
	board.territory_claimer.claim_territory(
		board.wall_registry,
		op.generator_position,
		endpoints,
		fireball_positions
	)

	# Remove fireballs trapped in claimed regions
	_fireball_manager.remove_fireballs_in_claimed()


func _on_operation_failed(_op: BuildOperation) -> void:
	pass  # Phase 5 will handle game over logic
