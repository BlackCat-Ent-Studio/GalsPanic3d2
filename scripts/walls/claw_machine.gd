extends Node3D
class_name ClawMachine
## Claw machine hovering above board. Holds generator block, drops on click.
## No cable — floating grabber with hub, 3 curved prongs, and held block.

signal drop_completed(board_pos: Vector2)

const HOVER_HEIGHT := 5.0
const FOLLOW_SPEED := 12.0

var _claw_pivot: Node3D
var _prong_left: Node3D
var _prong_right: Node3D
var _prong_front: Node3D
var _block: MeshInstance3D
var _block_material: StandardMaterial3D

var _target_xz: Vector2 = Vector2.ZERO
var _is_dropping: bool = false
var _current_config: Resource
var _is_valid: bool = true

# Swing physics
var _prev_pos: Vector3 = Vector3.ZERO
var _swing_velocity: Vector2 = Vector2.ZERO
var _swing_angle: Vector2 = Vector2.ZERO  # x = tilt on Z axis, y = tilt on X axis
const SWING_STRENGTH := 8.0
const SWING_DAMPING := 5.0
const SWING_MAX_ANGLE := 15.0


func _ready() -> void:
	_build_claw()
	position.y = HOVER_HEIGHT


func _process(delta: float) -> void:
	if _is_dropping:
		_update_swing(delta)
		return
	var target := Board.board_to_world(_target_xz, HOVER_HEIGHT)
	var old_pos := position
	position = position.lerp(target, FOLLOW_SPEED * delta)
	# Calculate movement velocity for swing
	var move_delta := position - old_pos
	_swing_velocity = Vector2(move_delta.x, move_delta.z) / maxf(delta, 0.001)
	_update_swing(delta)


func _update_swing(delta: float) -> void:
	# Movement velocity tilts the claw in opposite direction
	var target_angle := Vector2(
		clampf(-_swing_velocity.y * SWING_STRENGTH, -SWING_MAX_ANGLE, SWING_MAX_ANGLE),
		clampf(_swing_velocity.x * SWING_STRENGTH, -SWING_MAX_ANGLE, SWING_MAX_ANGLE)
	)
	# Spring back + damping
	_swing_angle = _swing_angle.lerp(target_angle, delta * SWING_DAMPING)
	# Decay velocity when not moving
	_swing_velocity = _swing_velocity.lerp(Vector2.ZERO, delta * 3.0)
	# Apply tilt to claw pivot
	if _claw_pivot:
		_claw_pivot.rotation_degrees.x = _swing_angle.x
		_claw_pivot.rotation_degrees.z = _swing_angle.y


func update_position(board_pos: Vector2, config: Resource, is_valid: bool) -> void:
	visible = true
	_target_xz = board_pos
	_is_valid = is_valid
	_current_config = config
	_update_block_color(is_valid)


func hide_claw() -> void:
	visible = false


func drop_block(board_pos: Vector2) -> void:
	if _is_dropping:
		return
	_is_dropping = true
	_target_xz = board_pos
	_open_prongs()

	# Create falling block (detached from claw)
	var fall_block := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.45, 0.45, 0.45)
	fall_block.mesh = box
	fall_block.material_override = _block_material.duplicate()
	get_tree().current_scene.add_child(fall_block)
	fall_block.global_position = _block.global_position
	_block.visible = false

	# Gravity fall + bounce
	var land_y := 0.3
	var tween := create_tween()
	tween.tween_property(fall_block, "position:y", land_y, 0.35)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(fall_block, "position:y", land_y + 0.15, 0.08)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(fall_block, "position:y", land_y, 0.08)\
		.set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		fall_block.queue_free()
		_on_block_landed()
	)


func _on_block_landed() -> void:
	_is_dropping = false
	drop_completed.emit(_target_xz)
	var tween := create_tween()
	tween.tween_interval(0.2)
	tween.tween_callback(func() -> void:
		_close_prongs()
		_block.visible = true
		if _current_config:
			_update_block_color(_is_valid)
	)


func _build_claw() -> void:
	_claw_pivot = Node3D.new()
	_claw_pivot.name = "ClawPivot"
	add_child(_claw_pivot)

	# Hub body (no cable)
	var hub := ClawVisualBuilder.create_hub()
	_claw_pivot.add_child(hub)

	# 3 curved prongs (each is a Node3D pivot with upper + tip segments)
	_prong_left = ClawVisualBuilder.create_prong(Vector3(-0.22, -0.15, 0), "z", 12.0)
	_claw_pivot.add_child(_prong_left)
	_prong_right = ClawVisualBuilder.create_prong(Vector3(0.22, -0.15, 0), "z", -12.0)
	_claw_pivot.add_child(_prong_right)
	_prong_front = ClawVisualBuilder.create_prong(Vector3(0, -0.15, 0.22), "x", -12.0)
	_claw_pivot.add_child(_prong_front)

	# Held block
	var block_arr: Array = ClawVisualBuilder.create_block()
	_block = block_arr[0]
	_block_material = block_arr[1]
	_claw_pivot.add_child(_block)


func _open_prongs() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_prong_left, "rotation_degrees:z", 30.0, 0.15)
	tw.tween_property(_prong_right, "rotation_degrees:z", -30.0, 0.15)
	tw.tween_property(_prong_front, "rotation_degrees:x", -30.0, 0.15)


func _close_prongs() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_prong_left, "rotation_degrees:z", 12.0, 0.15)
	tw.tween_property(_prong_right, "rotation_degrees:z", -12.0, 0.15)
	tw.tween_property(_prong_front, "rotation_degrees:x", -12.0, 0.15)


func _update_block_color(is_valid: bool) -> void:
	if not _block_material or not _current_config:
		return
	var c: Color = _current_config.preview_color if is_valid else Color(1.0, 0.2, 0.2)
	_block_material.albedo_color = Color(c, 0.9)
	_block_material.emission = Color(c, 1.0) * 0.3
