extends Node3D
class_name Fireball
## A single fireball enemy. Moves in patterns, bounces off walls.

var config: Resource  # FireballConfig
var board_position: Vector2 = Vector2.ZERO
var previous_position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var effective_speed: float = 3.0

var _wall_registry: WallRegistry
var _direction: Vector2 = Vector2.RIGHT
var _mesh: MeshInstance3D

# Curve state
var _curve_angle: float = 0.0
var _curve_center: Vector2 = Vector2.ZERO
var _curve_radius: float = 3.0
var _curve_ccw: bool = false

# Zigzag state
var _zigzag_time: float = 0.0
var _zigzag_base_dir: Vector2 = Vector2.RIGHT


func setup(p_config: Resource, pos: Vector2, registry: WallRegistry, level: int) -> void:
	config = p_config
	board_position = pos
	previous_position = pos
	_wall_registry = registry
	effective_speed = p_config.base_speed * (1.0 + p_config.speed_scale_per_level * level)

	# Random initial direction
	_direction = Vector2.from_angle(randf() * TAU)
	velocity = _direction * effective_speed

	# Pattern-specific init
	var pattern: int = p_config.pattern
	if pattern == 1:  # CURVE
		_curve_ccw = p_config.curve_ccw if randf() > 0.5 else not p_config.curve_ccw
		_curve_radius = maxf(1.0, p_config.curve_radius + p_config.curve_radius_scale * level)
		_curve_center = pos + _direction.rotated(PI / 2.0 if _curve_ccw else -PI / 2.0) * _curve_radius
		_curve_angle = (_direction.rotated(PI if _curve_ccw else PI)).angle()
	elif pattern == 2:  # ZIGZAG
		_zigzag_base_dir = _direction
		_zigzag_time = 0.0

	_create_visual()
	position = Board.board_to_world(board_position, 0.3)


func _create_visual() -> void:
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = config.radius
	sphere.height = config.radius * 2.0
	_mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = config.color
	mat.emission_enabled = true
	mat.emission = config.color * 0.6
	mat.emission_energy_multiplier = 1.5
	_mesh.material_override = mat
	add_child(_mesh)


func _physics_process(delta: float) -> void:
	previous_position = board_position
	_update_movement(delta)
	_check_wall_bouncing()
	_clamp_to_bounds()
	velocity = (board_position - previous_position) / maxf(delta, 0.001)
	position = Board.board_to_world(board_position, 0.3)


func _update_movement(delta: float) -> void:
	var pattern: int = config.pattern
	if pattern == 0:  # STRAIGHT
		board_position += _direction * effective_speed * delta
	elif pattern == 1:  # CURVE
		var angular_speed := effective_speed / _curve_radius
		if _curve_ccw:
			angular_speed = -angular_speed
		_curve_angle += angular_speed * delta
		board_position = _curve_center + Vector2(cos(_curve_angle), sin(_curve_angle)) * _curve_radius
	elif pattern == 2:  # ZIGZAG
		_zigzag_time += delta
		var interval: float = maxf(0.3, config.zigzag_interval + config.zigzag_interval_scale * 0)
		var lateral := sin(_zigzag_time * TAU / interval) * deg_to_rad(config.zigzag_angle)
		var dir := _zigzag_base_dir.rotated(lateral)
		board_position += dir * effective_speed * delta


func _check_wall_bouncing() -> void:
	var move_vec := board_position - previous_position
	var travel := move_vec.length()
	if travel < 0.001:
		return
	var move_dir := move_vec / travel

	for seg in _wall_registry.segments:
		var result := GeometryUtils.ray_segment_intersection(
			previous_position, move_dir, seg.start, seg.end
		)
		if result.is_empty():
			continue
		var t: float = result["t"]
		if t < -0.01 or t > travel + config.radius:
			continue

		# Reflect
		var hit_point: Vector2 = result["point"]
		var new_dir := GeometryCollisionUtils.reflect_off_segment(_direction, seg.start, seg.end)
		_apply_reflection(new_dir, hit_point)
		GameEvents.fireball_bounced.emit(self, hit_point)
		break  # One bounce per frame


func _apply_reflection(new_dir: Vector2, hit_point: Vector2) -> void:
	_direction = new_dir.normalized()
	# Nudge away from wall
	board_position = hit_point + _direction * 0.05

	var pattern: int = config.pattern
	if pattern == 1:  # CURVE: recalculate orbit center
		var perp := _direction.rotated(PI / 2.0 if _curve_ccw else -PI / 2.0)
		_curve_center = board_position + perp * _curve_radius
		_curve_angle = (board_position - _curve_center).angle()
	elif pattern == 2:  # ZIGZAG: update base direction
		_zigzag_base_dir = _direction


func _clamp_to_bounds() -> void:
	var margin: float = config.radius
	var clamped := false
	if board_position.x < -10.0 + margin:
		board_position.x = -10.0 + margin
		_direction.x = absf(_direction.x)
		clamped = true
	elif board_position.x > 10.0 - margin:
		board_position.x = 10.0 - margin
		_direction.x = -absf(_direction.x)
		clamped = true
	if board_position.y < -10.0 + margin:
		board_position.y = -10.0 + margin
		_direction.y = absf(_direction.y)
		clamped = true
	elif board_position.y > 10.0 - margin:
		board_position.y = 10.0 - margin
		_direction.y = -absf(_direction.y)
		clamped = true
	if clamped and config.pattern == 1:
		var perp := _direction.rotated(PI / 2.0 if _curve_ccw else -PI / 2.0)
		_curve_center = board_position + perp * _curve_radius
		_curve_angle = (board_position - _curve_center).angle()
