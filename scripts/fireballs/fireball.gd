extends Node3D
class_name Fireball
## A single fireball enemy. Moves in patterns, bounces off walls.
## All patterns use incremental movement (pos += dir * speed * dt) so
## bounce/clamp always works reliably.

var config: Resource  # FireballConfig
var board_position: Vector2 = Vector2.ZERO
var previous_position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var effective_speed: float = 3.0

var _wall_registry: WallRegistry
var _direction: Vector2 = Vector2.RIGHT
var _mesh: MeshInstance3D

## Optional lifespan in seconds. <= 0 means infinite (default).
var lifespan: float = 0.0
var _age: float = 0.0
## If true, fireball dies when entering claimed territory.
var dies_in_claimed: bool = false

# Curve state: gradually rotate direction each frame
var _curve_angular_speed: float = 0.0

# Zigzag state: oscillate direction around base heading
var _zigzag_time: float = 0.0
var _zigzag_base_angle: float = 0.0

# Bounce cooldown: skip pattern steering briefly after bounce
var _bounce_cooldown: float = 0.0
const BOUNCE_COOLDOWN_TIME := 0.15


func setup(p_config: Resource, pos: Vector2, registry: WallRegistry, level: int) -> void:
	config = p_config
	board_position = pos
	previous_position = pos
	_wall_registry = registry
	effective_speed = p_config.base_speed * (1.0 + p_config.speed_scale_per_level * level)

	_direction = Vector2.from_angle(randf() * TAU)
	velocity = _direction * effective_speed

	var pattern: int = p_config.pattern
	if pattern == 1:  # CURVE
		var curve_radius: float = maxf(1.0, p_config.curve_radius + p_config.curve_radius_scale * level)
		_curve_angular_speed = effective_speed / curve_radius
		if randf() > 0.5:
			_curve_angular_speed = -_curve_angular_speed
	elif pattern == 2:  # ZIGZAG
		_zigzag_base_angle = _direction.angle()
		_zigzag_time = 0.0

	_create_visual()
	_create_trail()
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


func _create_trail() -> void:
	var trail := FireballTrail.new()
	trail.setup(config.color)
	add_child(trail)


func _physics_process(delta: float) -> void:
	# Lifespan check
	if lifespan > 0.0:
		_age += delta
		if _age >= lifespan:
			_start_death_fade()
			return
		# Fade out during last 2 seconds
		if _age >= lifespan - 2.0 and _mesh and _mesh.material_override:
			var mat: StandardMaterial3D = _mesh.material_override
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var fade := 1.0 - (_age - (lifespan - 2.0)) / 2.0
			mat.albedo_color.a = maxf(fade, 0.1)

	# Die if in claimed territory
	if dies_in_claimed:
		for region in _wall_registry.regions:
			if region.is_claimed and region.contains_point(board_position):
				_start_death_fade()
				return

	previous_position = board_position

	# Update direction based on pattern (skip during bounce cooldown)
	_bounce_cooldown = maxf(0.0, _bounce_cooldown - delta)
	if _bounce_cooldown <= 0.0:
		_apply_pattern_steering(delta)

	# Move incrementally — same for all patterns
	board_position += _direction * effective_speed * delta

	# Bounce off walls
	_check_wall_bouncing()

	# Clamp to board bounds
	_clamp_to_bounds()

	velocity = (board_position - previous_position) / maxf(delta, 0.001)
	position = Board.board_to_world(board_position, 0.3)


func _apply_pattern_steering(delta: float) -> void:
	var pattern: int = config.pattern
	if pattern == 1:  # CURVE: rotate direction continuously
		_direction = _direction.rotated(_curve_angular_speed * delta)
	elif pattern == 2:  # ZIGZAG: oscillate around base heading
		_zigzag_time += delta
		var interval: float = maxf(0.3, config.zigzag_interval)
		var swing := sin(_zigzag_time * TAU / interval) * deg_to_rad(config.zigzag_angle)
		_direction = Vector2.from_angle(_zigzag_base_angle + swing)


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

		var hit_point: Vector2 = result["point"]
		var new_dir := GeometryCollisionUtils.reflect_off_segment(
			_direction, seg.start, seg.end
		)
		_do_bounce(new_dir, hit_point)
		GameEvents.fireball_bounced.emit(self, hit_point)
		break


func _do_bounce(new_dir: Vector2, hit_point: Vector2) -> void:
	_direction = new_dir.normalized()
	board_position = hit_point + _direction * 0.15
	_bounce_cooldown = BOUNCE_COOLDOWN_TIME

	var pattern: int = config.pattern
	if pattern == 1:  # Flip curve rotation direction
		_curve_angular_speed = -_curve_angular_speed
	elif pattern == 2:  # Reset zigzag base to new direction
		_zigzag_base_angle = _direction.angle()
		_zigzag_time = 0.0


func _clamp_to_bounds() -> void:
	var margin: float = config.radius + 0.15
	var bounced := false

	if board_position.x < -10.0 + margin:
		board_position.x = -10.0 + margin
		_direction.x = absf(_direction.x)
		bounced = true
	elif board_position.x > 10.0 - margin:
		board_position.x = 10.0 - margin
		_direction.x = -absf(_direction.x)
		bounced = true

	if board_position.y < -10.0 + margin:
		board_position.y = -10.0 + margin
		_direction.y = absf(_direction.y)
		bounced = true
	elif board_position.y > 10.0 - margin:
		board_position.y = 10.0 - margin
		_direction.y = -absf(_direction.y)
		bounced = true

	if bounced:
		# Ensure direction is never zero
		if _direction.length_squared() < 0.001:
			_direction = Vector2.from_angle(randf() * TAU)
		_bounce_cooldown = BOUNCE_COOLDOWN_TIME
		if config.pattern == 1:
			_curve_angular_speed = -_curve_angular_speed
		elif config.pattern == 2:
			_zigzag_base_angle = _direction.angle()
			_zigzag_time = 0.0


func _start_death_fade() -> void:
	set_physics_process(false)
	if _mesh:
		var tween := create_tween()
		tween.tween_property(_mesh, "scale", Vector3.ZERO, 0.3).set_ease(Tween.EASE_IN)
		tween.tween_callback(queue_free)
	else:
		queue_free()
