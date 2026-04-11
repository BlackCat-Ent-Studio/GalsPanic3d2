extends Node3D
class_name GameplayController
## Wires Board, Input, ClawMachine, Builds, Fireballs, DropItems together.

@export_node_path("Node3D") var board_path: NodePath
@export_node_path("Camera3D") var camera_path: NodePath

var board: Board
var camera: Camera3D

var _input_handler: InputHandler
var _claw_machine: ClawMachine
var _active_builds: Node3D
var _fireball_manager: FireballManager
var _drop_spawner: DropItemSpawner
var _pending_drop_pos: Vector2  # Board pos waiting for claw drop to complete


func _ready() -> void:
	board = get_node(board_path) as Board
	camera = get_node(camera_path) as Camera3D
	_setup_input_handler()
	_setup_claw_machine()
	_setup_active_builds()
	_setup_fireball_manager()
	_setup_drop_spawner()
	# Start level
	GameManager.start_level(GameManager.current_level_index)
	# Use positioned placements if available, otherwise legacy spawn entries
	var level_cfg: LevelConfig = GameManager.current_level_config
	if level_cfg and not level_cfg.fireball_placements.is_empty():
		_fireball_manager.spawn_from_placements(
			level_cfg.fireball_placements, GameManager.current_level_index)
	else:
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
	_input_handler.cursor_moved.connect(_on_cursor_moved)
	_input_handler.click_placed.connect(_on_click_placed)
	_input_handler.click_invalid.connect(_on_click_invalid)


func _setup_claw_machine() -> void:
	_claw_machine = ClawMachine.new()
	_claw_machine.name = "ClawMachine"
	add_child(_claw_machine)
	_claw_machine.drop_completed.connect(_on_claw_drop_completed)


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


func _on_cursor_moved(board_pos: Vector2) -> void:
	var is_valid := board.wall_registry.is_point_in_playable_area(board_pos)
	var config: Resource = GameManager.inventory.get_config_for_selected()
	_claw_machine.update_position(board_pos, config, is_valid)
	GameEvents.drag_started.emit()


func _on_click_placed(board_pos: Vector2) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	var inv := GameManager.inventory
	if not inv.is_available(inv.selected_type):
		inv.select_type(GeneratorInventory.TYPE_CROSS4)
	_claw_machine.drop_block(board_pos)


func _on_click_invalid() -> void:
	GameEvents.wall_placement_cancelled.emit()


## Called when claw finishes dropping block onto the board.
func _on_claw_drop_completed(board_pos: Vector2) -> void:
	_spawn_build_operation(board_pos)


func _spawn_build_operation(board_pos: Vector2) -> void:
	var inv := GameManager.inventory
	var config: Resource = inv.get_config_for_selected()
	inv.consume(inv.selected_type)

	var speed_mult := GameManager.power_up_manager.get_speed_multiplier()
	GameManager.power_up_manager.on_build_started()

	var op := BuildOperation.new()
	_active_builds.add_child(op)
	op.start(board_pos, config, board.wall_registry)

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
