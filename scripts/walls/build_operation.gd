extends Node3D
class_name BuildOperation
## Manages the full lifecycle of one wall generator placement.
## Spawns N BuildArm children, tracks completion, registers segments.

signal operation_completed(op: BuildOperation)
signal operation_failed(op: BuildOperation)

var generator_position: Vector2
var config: Resource
var wall_registry: WallRegistry

var arms: Array[BuildArm] = []
var completed_arms: Array[BuildArm] = []
var destroyed_arms: Array[BuildArm] = []
var life_lost_this_op: bool = false

var _generator_mesh: MeshInstance3D
var _is_finalized: bool = false


func start(pos: Vector2, cfg: Resource, registry: WallRegistry) -> void:
	generator_position = pos
	config = cfg
	wall_registry = registry
	position = Board.board_to_world(pos, 0.0)

	_create_generator_visual(pos)

	for dir: Vector2 in cfg.arms:
		var hit := registry.raycast_to_wall(pos, dir)
		if hit.is_empty():
			continue
		var arm := BuildArm.new()
		add_child(arm)
		arm.setup(pos, hit["point"], dir, cfg.build_speed)
		arm.arm_completed.connect(_on_arm_completed)
		arm.arm_destroyed.connect(_on_arm_destroyed)
		arms.append(arm)

	if arms.is_empty():
		_finalize_failure()

	GameEvents.wall_placement_started.emit()


func _create_generator_visual(pos: Vector2) -> void:
	_generator_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	_generator_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.7, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.4, 0.7)
	mat.emission_energy_multiplier = 0.8
	_generator_mesh.material_override = mat
	_generator_mesh.position = Vector3(0.0, 0.3, 0.0)
	add_child(_generator_mesh)


func _on_arm_completed(arm: BuildArm) -> void:
	if _is_finalized:
		return
	completed_arms.append(arm)
	# Register segment immediately
	if not arm.is_registered:
		arm.is_registered = true
		wall_registry.add_segment(arm.to_wall_segment())
	_check_all_done()


func _on_arm_destroyed(arm: BuildArm) -> void:
	if _is_finalized:
		return
	destroyed_arms.append(arm)
	if not life_lost_this_op:
		life_lost_this_op = true
		GameEvents.life_lost.emit()
		GameEvents.arm_destroyed.emit()
	_check_all_done()


func _check_all_done() -> void:
	var total_resolved := completed_arms.size() + destroyed_arms.size()
	if total_resolved < arms.size():
		return
	# All arms resolved
	if completed_arms.is_empty():
		_finalize_failure()
	else:
		_finalize_success()


func _finalize_success() -> void:
	if _is_finalized:
		return
	_is_finalized = true
	# Emit wall_completed with data for territory claiming (Phase 3)
	var segment_data: Array[Dictionary] = []
	for arm in completed_arms:
		segment_data.append({
			"start": arm.start_pos,
			"end": arm.end_pos,
			"direction": arm.direction
		})
	GameEvents.wall_completed.emit({
		"position": generator_position,
		"segments": segment_data,
		"completed_arms": completed_arms.size(),
		"total_arms": arms.size()
	})
	# Keep generator visual as permanent marker
	if _generator_mesh:
		var mat: StandardMaterial3D = _generator_mesh.material_override
		mat.emission_enabled = false
		mat.albedo_color = Color(0.6, 0.6, 0.65)
	operation_completed.emit(self)


func _finalize_failure() -> void:
	if _is_finalized:
		return
	_is_finalized = true
	GameEvents.generator_destroyed.emit()
	operation_failed.emit(self)
	# Spawn explosion VFX
	var explosion := ExplosionEffect.new()
	explosion.setup(Board.board_to_world(generator_position, 0.3))
	get_tree().current_scene.add_child(explosion)
	# Fade out and remove
	var tween := create_tween()
	if _generator_mesh and _generator_mesh.material_override:
		_generator_mesh.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(_generator_mesh.material_override, "albedo_color:a", 0.0, 0.5)
	tween.tween_callback(queue_free)


## Called by fireball system to damage an arm.
func damage_arm_at(fireball_pos: Vector2, damage_radius: float = 0.25) -> bool:
	for arm in arms:
		if not is_instance_valid(arm) or arm.is_completed or arm.is_destroyed:
			continue
		var tip := arm.get_current_tip()
		# Check distance from fireball to arm line
		var dist := GeometryUtils.point_to_segment_distance(fireball_pos, arm.start_pos, tip)
		if dist < damage_radius:
			arm.start_dissolve()
			return true
	return false
