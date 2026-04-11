extends Node3D
class_name GameplayController
## Wires Board, Input, Preview, Builds, Fireballs, DropItems together.

@export_node_path("Node3D") var board_path: NodePath
@export_node_path("Camera3D") var camera_path: NodePath

var board: Board
var camera: Camera3D

var _input_handler: InputHandler
var _wall_preview: WallPreview
var _active_builds: Node3D
var _fireball_manager: FireballManager
var _drop_spawner: DropItemSpawner


func _ready() -> void:
	board = get_node(board_path) as Board
	camera = get_node(camera_path) as Camera3D
	_setup_input_handler()
	_setup_wall_preview()
	_setup_active_builds()
	_setup_fireball_manager()
	_setup_drop_spawner()
	# Start level
	GameManager.start_level(GameManager.current_level_index)
	var entries: Array = GameManager.get_spawn_entries_for_manager()
	_fireball_manager.spawn_fireballs(entries, GameManager.current_level_index)


func _physics_process(_delta: float) -> void:
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


func _setup_drop_spawner() -> void:
	_drop_spawner = DropItemSpawner.new()
	_drop_spawner.name = "DropItems"
	add_child(_drop_spawner)
	_drop_spawner.setup(board.wall_registry, GameManager.inventory)


func _on_drag_started(board_pos: Vector2) -> void:
	_update_preview(board_pos)
	GameEvents.drag_started.emit()


func _on_drag_updated(board_pos: Vector2) -> void:
	_update_preview(board_pos)


func _on_drag_ended(board_pos: Vector2) -> void:
	_wall_preview.hide_preview()
	if GameManager.state != GameManager.State.PLAYING:
		return
	# Check inventory
	var inv := GameManager.inventory
	if not inv.is_available(inv.selected_type):
		inv.select_type(GeneratorInventory.TYPE_CROSS4)
	_spawn_build_operation(board_pos)


func _on_drag_cancelled() -> void:
	_wall_preview.hide_preview()
	GameEvents.wall_placement_cancelled.emit()


func _update_preview(board_pos: Vector2) -> void:
	var is_valid := board.wall_registry.is_point_in_playable_area(board_pos)
	var config: Resource = GameManager.inventory.get_config_for_selected()
	_wall_preview.show_preview(board_pos, config, board.wall_registry, is_valid)


func _spawn_build_operation(board_pos: Vector2) -> void:
	var inv := GameManager.inventory
	var config: Resource = inv.get_config_for_selected()
	inv.consume(inv.selected_type)

	# Apply power-up speed multiplier
	var speed_mult := GameManager.power_up_manager.get_speed_multiplier()
	GameManager.power_up_manager.on_build_started()

	var op := BuildOperation.new()
	_active_builds.add_child(op)
	op.start(board_pos, config, board.wall_registry)

	# Apply speed multiplier to arms
	if speed_mult > 1.0:
		for arm: BuildArm in op.arms:
			arm.build_speed *= speed_mult

	op.operation_completed.connect(_on_operation_completed)
	op.operation_failed.connect(_on_operation_failed)


func _on_operation_completed(op: BuildOperation) -> void:
	GameManager.power_up_manager.on_build_finished()

	var endpoints := PackedVector2Array()
	for arm: BuildArm in op.completed_arms:
		endpoints.append(arm.end_pos)

	var fireball_positions := _fireball_manager.get_fireball_positions()
	board.territory_claimer.claim_territory(
		board.wall_registry, op.generator_position, endpoints, fireball_positions
	)
	_fireball_manager.remove_fireballs_in_claimed()


func _on_operation_failed(_op: BuildOperation) -> void:
	GameManager.power_up_manager.on_build_finished()
