extends Fireball
class_name BossFireball
## Boss fireball with unique movement patterns. Invincible, targets walls only.
## Boss 1 (Tank): patrols → locks on → charges claimed walls → unclaims territory.
## Boss 2 (Ghost): drifts → phases through unclaimed walls → dissolves them.

enum TankState { PATROL, LOCK_ON, CHARGE, COOLDOWN }
enum GhostState { DRIFT, PHASE_THROUGH, DISSOLVE }

var _fireball_manager: Node  # FireballManager reference
var _boss_type: int = 0

# Summoning (shared)
var _summon_timer: float = 0.0
var _spawned_minis: Array[Fireball] = []

# Tank state
var _tank_state: TankState = TankState.PATROL
var _tank_timer: float = 0.0
var _charge_target: WallSegment = null
var _charge_target_pos: Vector2 = Vector2.ZERO
const PATROL_DURATION := 4.0
const LOCK_ON_DURATION := 1.0
const CHARGE_SPEED_MULT := 3.0
const CHARGE_TIMEOUT := 5.0
const COOLDOWN_DURATION := 3.0
const CHARGE_HIT_DIST := 0.5

# Ghost state
var _ghost_state: GhostState = GhostState.DRIFT
var _ghost_timer: float = 0.0
var _dissolve_target: WallSegment = null
var _drift_time: float = 0.0
var _ghost_seek_timer: float = 0.0
var _ghost_seek_target: Vector2 = Vector2.ZERO
var _ghost_has_target: bool = false
const DISSOLVE_DELAY := 1.5
const GHOST_DISSOLVE_COOLDOWN := 2.0
const GHOST_SEEK_INTERVAL := 3.0

# Ghost visibility (existing mechanic)
var _visibility_timer: float = 0.0
var _is_visible: bool = true


func setup(p_config: Resource, pos: Vector2, registry: WallRegistry, level: int) -> void:
	super.setup(p_config, pos, registry, level)
	_boss_type = config.boss_type

	# Tank: halve base speed for patrol
	if _boss_type == 1:
		effective_speed *= 0.5

	# Larger visual
	if _mesh:
		var sphere: SphereMesh = _mesh.mesh
		sphere.radius = config.radius * 2.0
		sphere.height = config.radius * 4.0
		var mat: StandardMaterial3D = _mesh.material_override
		mat.emission_energy_multiplier = 3.0


func set_fireball_manager(manager: Node) -> void:
	_fireball_manager = manager


func _physics_process(delta: float) -> void:
	previous_position = board_position
	_update_summon(delta)

	if _boss_type == 1:
		_tank_process(delta)
	elif _boss_type == 2:
		_ghost_process(delta)
		_update_ghost_visibility(delta)
	else:
		super._physics_process(delta)
		return

	velocity = (board_position - previous_position) / maxf(delta, 0.001)
	position = Board.board_to_world(board_position, 0.3)


# =============================================================================
# TANK BOSS — The Charger
# =============================================================================

func _tank_process(delta: float) -> void:
	_tank_timer += delta
	match _tank_state:
		TankState.PATROL:
			_tank_patrol(delta)
		TankState.LOCK_ON:
			_tank_lock_on(delta)
		TankState.CHARGE:
			_tank_charge(delta)
		TankState.COOLDOWN:
			_tank_cooldown()


func _tank_patrol(delta: float) -> void:
	# Slow curve movement while scanning
	_bounce_cooldown = maxf(0.0, _bounce_cooldown - delta)
	if _bounce_cooldown <= 0.0:
		_direction = _direction.rotated(0.5 * delta)  # gentle curve
	board_position += _direction * effective_speed * delta
	_check_wall_bouncing()
	_clamp_to_bounds()

	if _tank_timer >= PATROL_DURATION:
		_try_acquire_tank_target()


func _try_acquire_tank_target() -> void:
	var candidates := _wall_registry.find_segments_bordering_claimed()
	if candidates.is_empty():
		_tank_timer = PATROL_DURATION * 0.5  # Retry sooner
		return
	# Pick closest segment
	var best_seg: WallSegment = null
	var best_dist := INF
	for seg in candidates:
		var mid := (seg.start + seg.end) * 0.5
		var dist := board_position.distance_squared_to(mid)
		if dist < best_dist:
			best_dist = dist
			best_seg = seg
	_charge_target = best_seg
	_charge_target_pos = (_charge_target.start + _charge_target.end) * 0.5
	_tank_state = TankState.LOCK_ON
	_tank_timer = 0.0
	# Flash warning
	_flash_boss_color(Color.ORANGE_RED)


func _tank_lock_on(delta: float) -> void:
	# Face target, brief pause
	if _charge_target:
		_direction = (_charge_target_pos - board_position).normalized()
	# Slight forward creep during lock-on
	board_position += _direction * effective_speed * 0.2 * delta
	_clamp_to_bounds()

	if _tank_timer >= LOCK_ON_DURATION:
		_tank_state = TankState.CHARGE
		_tank_timer = 0.0


func _tank_charge(delta: float) -> void:
	# Abort if target was destroyed externally
	if _charge_target == null or not _wall_registry.segments.has(_charge_target):
		_charge_target = null
		_tank_state = TankState.COOLDOWN
		_tank_timer = 0.0
		_flash_boss_color(config.color)
		return
	# Charge at high speed toward target
	var charge_speed := effective_speed * CHARGE_SPEED_MULT
	_direction = (_charge_target_pos - board_position).normalized()
	board_position += _direction * charge_speed * delta
	_clamp_to_bounds()

	# Check if reached target
	var dist := board_position.distance_to(_charge_target_pos)
	if dist < CHARGE_HIT_DIST:
		_tank_impact()
		return

	# Timeout — target may have been destroyed
	if _tank_timer >= CHARGE_TIMEOUT:
		_tank_state = TankState.COOLDOWN
		_tank_timer = 0.0
		_flash_boss_color(config.color)


func _tank_impact() -> void:
	if _charge_target and _wall_registry.segments.has(_charge_target):
		# Find adjacent claimed region before destroying wall
		var claimed_region := _wall_registry.find_claimed_region_near_segment(_charge_target)
		# Destroy the wall
		_wall_registry.destroy_segment(_charge_target)
		# Unclaim the territory
		if claimed_region:
			_wall_registry.unclaim_region(claimed_region)
		# VFX
		GameEvents.fireball_bounced.emit(self, _charge_target_pos)
		_shake_camera()

	_charge_target = null
	_tank_state = TankState.COOLDOWN
	_tank_timer = 0.0
	_flash_boss_color(config.color)


func _tank_cooldown() -> void:
	if _tank_timer >= COOLDOWN_DURATION:
		_tank_state = TankState.PATROL
		_tank_timer = 0.0
		# Pick new random direction for patrol
		_direction = Vector2.from_angle(randf() * TAU)


# =============================================================================
# GHOST BOSS — The Infiltrator
# =============================================================================

func _ghost_process(delta: float) -> void:
	_ghost_timer += delta
	match _ghost_state:
		GhostState.DRIFT:
			_ghost_drift(delta)
		GhostState.PHASE_THROUGH:
			_ghost_phase_through(delta)
		GhostState.DISSOLVE:
			_ghost_dissolve()


func _ghost_drift(delta: float) -> void:
	_drift_time += delta
	_bounce_cooldown = maxf(0.0, _bounce_cooldown - delta)

	# Periodically seek nearest unclaimed wall
	_ghost_seek_timer += delta
	if _ghost_seek_timer >= GHOST_SEEK_INTERVAL:
		_ghost_seek_timer = 0.0
		_ghost_acquire_target()

	# Steer toward target if we have one, otherwise sine-wave drift
	if _ghost_has_target and _bounce_cooldown <= 0.0:
		var to_target := (_ghost_seek_target - board_position).normalized()
		# Blend toward target direction
		_direction = _direction.lerp(to_target, 2.0 * delta).normalized()
		# Clear target when close enough
		if board_position.distance_to(_ghost_seek_target) < 1.0:
			_ghost_has_target = false
	elif _bounce_cooldown <= 0.0:
		var wave := sin(_drift_time * 1.5) * 0.8
		_direction = _direction.rotated(wave * delta)

	board_position += _direction * effective_speed * delta

	# Check wall collision — phase through unclaimed walls, bounce off claimed
	_ghost_check_walls()
	_clamp_to_bounds()


func _ghost_acquire_target() -> void:
	var candidates := _wall_registry.find_segments_bordering_unclaimed()
	if candidates.is_empty():
		_ghost_has_target = false
		return
	# Pick closest non-boundary segment
	var best_seg: WallSegment = null
	var best_dist := INF
	for seg in candidates:
		var mid := (seg.start + seg.end) * 0.5
		var dist := board_position.distance_squared_to(mid)
		if dist < best_dist:
			best_dist = dist
			best_seg = seg
	if best_seg:
		_ghost_seek_target = (best_seg.start + best_seg.end) * 0.5
		_ghost_has_target = true


func _ghost_check_walls() -> void:
	var move_vec := board_position - previous_position
	var travel := move_vec.length()
	if travel < 0.001:
		return
	var move_dir := move_vec / travel

	for seg in _wall_registry.segments:
		if seg.is_boundary:
			# Bounce off boundaries normally
			var result := GeometryUtils.ray_segment_intersection(
				previous_position, move_dir, seg.start, seg.end
			)
			if result.is_empty():
				continue
			var t: float = result["t"]
			if t < -0.01 or t > travel + config.radius:
				continue
			_do_bounce(
				GeometryCollisionUtils.reflect_off_segment(_direction, seg.start, seg.end),
				result["point"]
			)
			return

		# Non-boundary wall: check if it borders unclaimed territory
		var result := GeometryUtils.ray_segment_intersection(
			previous_position, move_dir, seg.start, seg.end
		)
		if result.is_empty():
			continue
		var t: float = result["t"]
		if t < -0.01 or t > travel + config.radius:
			continue

		if _wall_registry._segment_borders_type(seg, false) and _dissolve_target == null:
			# Borders unclaimed → phase through and mark for dissolution
			_dissolve_target = seg
			_ghost_state = GhostState.PHASE_THROUGH
			_ghost_timer = 0.0
			# Don't bounce — pass through
			return
		elif _wall_registry._segment_borders_type(seg, false):
			# Already have a dissolve target, just pass through silently
			return
		else:
			# Borders only claimed → bounce normally
			_do_bounce(
				GeometryCollisionUtils.reflect_off_segment(_direction, seg.start, seg.end),
				result["point"]
			)
			return


func _ghost_phase_through(delta: float) -> void:
	# Continue moving through (no wall collision during phase)
	board_position += _direction * effective_speed * delta
	_clamp_to_bounds()

	# Brief translucent flash
	if _ghost_timer >= 0.5:
		_ghost_state = GhostState.DISSOLVE
		_ghost_timer = 0.0


func _ghost_dissolve() -> void:
	if _ghost_timer >= DISSOLVE_DELAY:
		# Destroy the wall segment
		if _dissolve_target and _wall_registry.segments.has(_dissolve_target):
			_wall_registry.destroy_segment(_dissolve_target)
			GameEvents.fireball_bounced.emit(self, (_dissolve_target.start + _dissolve_target.end) * 0.5)
		_dissolve_target = null
		_ghost_state = GhostState.DRIFT
		_ghost_timer = -GHOST_DISSOLVE_COOLDOWN  # Negative timer = cooldown before next dissolve


# =============================================================================
# SHARED UTILITIES
# =============================================================================

func _update_summon(delta: float) -> void:
	if _fireball_manager == null:
		return
	_summon_timer += delta
	var interval: float = config.summon_interval
	if _summon_timer < interval:
		return
	_summon_timer = 0.0

	# Clean dead refs
	_spawned_minis = _spawned_minis.filter(
		func(fb: Fireball) -> bool: return is_instance_valid(fb) and fb.is_inside_tree()
	)

	if _spawned_minis.size() >= config.max_summons:
		return

	# Spawn mini near boss position
	var offset := Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
	var spawn_pos := board_position + offset
	spawn_pos.x = clampf(spawn_pos.x, -9.0, 9.0)
	spawn_pos.y = clampf(spawn_pos.y, -9.0, 9.0)

	var type_configs := {
		"red": "res://resources/fireball_red.tres",
		"yellow": "res://resources/fireball_yellow.tres",
		"white": "res://resources/fireball_white.tres",
	}
	var summon_t: String = config.summon_type
	var cfg_path: String = type_configs.get(summon_t, type_configs["red"])
	var mini_cfg: Resource = load(cfg_path)
	var mini := Fireball.new()
	_fireball_manager.add_child(mini)
	mini.setup(mini_cfg, spawn_pos, _wall_registry, 0)
	_spawned_minis.append(mini)


func _update_ghost_visibility(delta: float) -> void:
	_visibility_timer += delta
	var on_time: float = config.invisible_on_time
	var off_time: float = config.invisible_off_time
	var cycle := on_time + off_time

	var t := fmod(_visibility_timer, cycle)
	var should_visible := t < on_time

	if should_visible != _is_visible:
		_is_visible = should_visible
		if _mesh and _mesh.material_override:
			var mat: StandardMaterial3D = _mesh.material_override
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var target_alpha := 1.0 if _is_visible else 0.05
			var tween := create_tween()
			tween.tween_property(mat, "albedo_color:a", target_alpha, 0.5)
			var target_emission := 3.0 if _is_visible else 0.0
			tween.parallel().tween_property(mat, "emission_energy_multiplier", target_emission, 0.5)


func _flash_boss_color(color: Color) -> void:
	if _mesh and _mesh.material_override:
		var mat: StandardMaterial3D = _mesh.material_override
		var original_color: Color = config.color
		mat.albedo_color = color
		mat.emission = color * 0.6
		var tween := create_tween()
		tween.tween_interval(0.3)
		tween.tween_callback(func() -> void:
			mat.albedo_color = original_color
			mat.emission = original_color * 0.6
		)


func _shake_camera() -> void:
	# Use existing camera shake system
	var cam := get_viewport().get_camera_3d()
	if cam:
		var shake_node := cam.get_node_or_null("CameraShake")
		if shake_node and shake_node.has_method("shake"):
			shake_node.shake(0.4, 0.3)
