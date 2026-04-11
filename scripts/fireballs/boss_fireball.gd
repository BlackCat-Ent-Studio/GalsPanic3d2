extends Fireball
class_name BossFireball
## Boss fireball with unique movement patterns. Invincible, targets walls only.
## Boss 1 (Tank): patrols → locks on → charges claimed walls → unclaims territory.
## Boss 2 (Ghost): invisible drift → appears → throws mini at screen → vanishes.

enum TankState { PATROL, LOCK_ON, CHARGE, COOLDOWN }
enum GhostState { DRIFT, APPEAR, THROW, VANISH }

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
var _drift_time: float = 0.0
var _ghost_throw_interval: float = 10.0  # Time between throws
const GHOST_APPEAR_DURATION := 0.8
const GHOST_THROW_DURATION := 1.2  # Arc animation time
const GHOST_VANISH_DURATION := 0.5

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
# GHOST BOSS — The Summoner
# =============================================================================

func _ghost_process(delta: float) -> void:
	_ghost_timer += delta
	match _ghost_state:
		GhostState.DRIFT:
			_ghost_drift(delta)
		GhostState.APPEAR:
			_ghost_appear(delta)
		GhostState.THROW:
			_ghost_throw(delta)
		GhostState.VANISH:
			_ghost_vanish(delta)


func _ghost_drift(delta: float) -> void:
	# Invisible movement — bounce off all walls normally
	_drift_time += delta
	_bounce_cooldown = maxf(0.0, _bounce_cooldown - delta)
	if _bounce_cooldown <= 0.0:
		var wave := sin(_drift_time * 1.5) * 0.8
		_direction = _direction.rotated(wave * delta)

	board_position += _direction * effective_speed * delta
	_check_wall_bouncing()
	_clamp_to_bounds()

	# Check if time to appear and throw
	if _ghost_timer >= _ghost_throw_interval:
		_ghost_start_appear()


func _ghost_start_appear() -> void:
	_ghost_state = GhostState.APPEAR
	_ghost_timer = 0.0
	# Force visible with dramatic flash
	_is_visible = true
	if _mesh and _mesh.material_override:
		var mat: StandardMaterial3D = _mesh.material_override
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.0
		var tween := create_tween()
		tween.tween_property(mat, "albedo_color:a", 1.0, 0.3)
		tween.parallel().tween_property(mat, "emission_energy_multiplier", 5.0, 0.3)
	_flash_boss_color(Color.MAGENTA)


func _ghost_appear(delta: float) -> void:
	# Stay still, pulsing — building tension
	# Don't move during appear
	if _ghost_timer >= GHOST_APPEAR_DURATION:
		_ghost_state = GhostState.THROW
		_ghost_timer = 0.0
		_ghost_spawn_throw_projectile()


func _ghost_spawn_throw_projectile() -> void:
	# Clean dead refs
	_spawned_minis = _spawned_minis.filter(
		func(fb: Fireball) -> bool: return is_instance_valid(fb) and fb.is_inside_tree()
	)
	if _spawned_minis.size() >= config.max_summons:
		return
	if _fireball_manager == null:
		return

	# Landing position: random point in unclaimed area
	var landing := Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))

	# Create the arc projectile visual (3D sphere that arcs up to screen then down)
	var projectile := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	projectile.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = config.color
	mat.emission_enabled = true
	mat.emission = config.color
	mat.emission_energy_multiplier = 4.0
	projectile.material_override = mat
	get_tree().current_scene.add_child(projectile)

	var start_3d := Board.board_to_world(board_position, 0.3)
	# Screen position: vertical wall at Z = -10, Y ~6 (center of screen)
	var screen_hit := Vector3(landing.x * 0.5, 6.0, -10.0)
	var land_3d := Board.board_to_world(landing, 0.3)

	projectile.global_position = start_3d

	# Arc: boss → screen (arc up) → board (arc down)
	var tween := create_tween()
	# Phase 1: arc up to screen
	var mid_up := (start_3d + screen_hit) * 0.5
	mid_up.y = 12.0  # High arc
	tween.tween_method(
		func(t: float) -> void:
			var a: Vector3 = start_3d.lerp(mid_up, t)
			var b: Vector3 = mid_up.lerp(screen_hit, t)
			projectile.global_position = a.lerp(b, t),
		0.0, 1.0, GHOST_THROW_DURATION * 0.5
	)
	# Phase 2: bounce down from screen to board
	var mid_down := (screen_hit + land_3d) * 0.5
	mid_down.y = 4.0  # Lower bounce arc
	tween.tween_method(
		func(t: float) -> void:
			var a: Vector3 = screen_hit.lerp(mid_down, t)
			var b: Vector3 = mid_down.lerp(land_3d, t)
			projectile.global_position = a.lerp(b, t),
		0.0, 1.0, GHOST_THROW_DURATION * 0.5
	)
	# On landing: remove projectile visual, spawn real fireball
	tween.tween_callback(func() -> void:
		projectile.queue_free()
		_ghost_land_mini(landing)
	)


func _ghost_land_mini(landing: Vector2) -> void:
	if _fireball_manager == null:
		return
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
	mini.setup(mini_cfg, landing, _wall_registry, 0)
	_spawned_minis.append(mini)
	# Impact VFX
	_shake_camera()


func _ghost_throw(delta: float) -> void:
	# Wait for throw animation to complete
	if _ghost_timer >= GHOST_THROW_DURATION:
		_ghost_state = GhostState.VANISH
		_ghost_timer = 0.0


func _ghost_vanish(delta: float) -> void:
	# Fade out
	if _ghost_timer < 0.1:
		if _mesh and _mesh.material_override:
			var mat: StandardMaterial3D = _mesh.material_override
			var tween := create_tween()
			tween.tween_property(mat, "albedo_color:a", 0.05, GHOST_VANISH_DURATION)
			tween.parallel().tween_property(mat, "emission_energy_multiplier", 0.0, GHOST_VANISH_DURATION)
	# Resume drifting after vanish
	if _ghost_timer >= GHOST_VANISH_DURATION:
		_is_visible = false
		_ghost_state = GhostState.DRIFT
		_ghost_timer = 0.0
		_ghost_throw_interval = randf_range(8.0, 12.0)  # Randomize next interval
		_direction = Vector2.from_angle(randf() * TAU)


# =============================================================================
# SHARED UTILITIES
# =============================================================================

func _update_summon(delta: float) -> void:
	# Ghost boss uses its own throw mechanic, not shared summon
	if _boss_type == 2:
		return
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
