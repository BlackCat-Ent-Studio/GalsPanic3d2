extends Node3D
class_name BuildArm
## Single directional wall arm. Extends from generator toward boundary.

signal arm_completed(arm: BuildArm)
signal arm_destroyed(arm: BuildArm)

var start_pos: Vector2
var end_pos: Vector2
var direction: Vector2
var build_speed: float = 5.0

var progress: float = 0.0
var is_completed: bool = false
var is_destroyed: bool = false
var is_registered: bool = false

var _total_length: float = 0.0
var _mesh: MeshInstance3D
var _wall_material: StandardMaterial3D


func setup(p_start: Vector2, p_end: Vector2, p_dir: Vector2, p_speed: float) -> void:
	start_pos = p_start
	end_pos = p_end
	direction = p_dir
	build_speed = p_speed
	_total_length = start_pos.distance_to(end_pos)

	if _total_length < 0.01:
		is_completed = true
		return

	_create_visual()


func _create_visual() -> void:
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.15, 1.0)  # Thin wall, scaled in _process
	_mesh.mesh = box

	_wall_material = StandardMaterial3D.new()
	_wall_material.albedo_color = Color(0.7, 0.85, 1.0)
	_wall_material.emission_enabled = true
	_wall_material.emission = Color(0.3, 0.5, 0.8)
	_wall_material.emission_energy_multiplier = 0.5
	_mesh.material_override = _wall_material

	add_child(_mesh)
	_update_visual()


func _process(delta: float) -> void:
	if is_completed or is_destroyed:
		set_process(false)
		return
	progress += build_speed * delta / _total_length
	if progress >= 1.0:
		progress = 1.0
		is_completed = true
		_finalize_visual()
		arm_completed.emit(self)
	_update_visual()


func _update_visual() -> void:
	if _mesh == null:
		return
	var current_length := _total_length * progress
	var tip_2d := start_pos + direction * (current_length)
	var mid_2d := (start_pos + tip_2d) * 0.5

	# Position in world space
	_mesh.global_position = Board.board_to_world(mid_2d, 0.075)
	var box: BoxMesh = _mesh.mesh
	box.size.z = current_length
	# Rotate to face direction
	var angle := atan2(direction.x, direction.y)
	_mesh.rotation = Vector3(0.0, angle, 0.0)


func _finalize_visual() -> void:
	if _wall_material:
		_wall_material.albedo_color = Color(0.9, 0.9, 0.95)
		_wall_material.emission_enabled = false


## Get current tip position in board space.
func get_current_tip() -> Vector2:
	var current_length := _total_length * progress
	return start_pos + direction * current_length


## Create WallSegment from this arm.
func to_wall_segment() -> WallSegment:
	return WallSegment.new(start_pos, end_pos, false)


## Start dissolution (called when fireball hits arm).
func start_dissolve(duration: float = 0.5) -> void:
	if is_destroyed:
		return
	is_destroyed = true
	is_completed = false
	set_process(false)
	# Simple fade-out
	if _wall_material:
		_wall_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var tween := create_tween()
		tween.tween_property(_wall_material, "albedo_color:a", 0.0, duration)
		tween.tween_callback(_on_dissolve_finished)


func _on_dissolve_finished() -> void:
	arm_destroyed.emit(self)
	queue_free()
