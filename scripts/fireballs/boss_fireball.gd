extends Fireball
class_name BossFireball
## Boss fireball: larger, summons minis, optional invisibility.
## Boss 1 (Tank): slow, always visible, summons minis.
## Boss 2 (Ghost): normal speed, cycles visible/invisible, summons minis.

var _summon_timer: float = 0.0
var _spawned_minis: Array[Fireball] = []
var _fireball_manager: Node  # FireballManager reference

# Ghost invisibility state
var _visibility_timer: float = 0.0
var _is_visible: bool = true
var _boss_type: int = 0


func setup(p_config: Resource, pos: Vector2, registry: WallRegistry, level: int) -> void:
	super.setup(p_config, pos, registry, level)
	_boss_type = config.boss_type

	# Boss 1 (Tank): halve speed
	if _boss_type == 1:
		effective_speed *= 0.5

	# Larger visual
	if _mesh:
		var sphere: SphereMesh = _mesh.mesh
		sphere.radius = config.radius * 2.0
		sphere.height = config.radius * 4.0
		# Boss glow
		var mat: StandardMaterial3D = _mesh.material_override
		mat.emission_energy_multiplier = 3.0


func set_fireball_manager(manager: Node) -> void:
	_fireball_manager = manager


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_summon(delta)
	if _boss_type == 2:
		_update_ghost_visibility(delta)


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

	# Check max
	var max_s: int = config.max_summons
	if _spawned_minis.size() >= max_s:
		return

	# Spawn mini near boss position
	var offset := Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
	var spawn_pos := board_position + offset
	# Clamp to board
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
			# Also fade emission
			var target_emission := 3.0 if _is_visible else 0.0
			tween.parallel().tween_property(mat, "emission_energy_multiplier", target_emission, 0.5)

	# Even when invisible, boss still destroys arms (collision still active)
