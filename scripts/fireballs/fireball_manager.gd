extends Node3D
class_name FireballManager
## Spawns fireballs, handles inter-fireball collision, provides positions for Qix rule.

var _wall_registry: WallRegistry


func setup(registry: WallRegistry) -> void:
	_wall_registry = registry
	add_to_group("fireballs")


## Spawn fireballs from config entries: [{config: Resource, count: int}]
func spawn_fireballs(spawn_entries: Array, level: int) -> void:
	for entry: Dictionary in spawn_entries:
		var cfg: Resource = entry["config"]
		var count: int = entry["count"]
		for i in count:
			var pos: Variant = _find_valid_spawn_position()
			if pos == null:
				continue
			var fb := Fireball.new()
			add_child(fb)
			fb.setup(cfg, pos, _wall_registry, level)


## Spawn fireballs from positioned placements: [{type, position, speed, radius}]
func spawn_from_placements(placements: Array, level: int) -> void:
	var type_configs := {
		"red": preload("res://resources/fireball_red.tres"),
		"yellow": preload("res://resources/fireball_yellow.tres"),
		"white": preload("res://resources/fireball_white.tres"),
		"boss_tank": preload("res://resources/fireball_boss_tank.tres"),
		"boss_ghost": preload("res://resources/fireball_boss_ghost.tres"),
	}
	for p: Dictionary in placements:
		var type_key: String = p["type"]
		var cfg: Resource = type_configs.get(type_key)
		if cfg == null:
			continue
		var pos: Vector2 = p["position"]
		var is_boss: bool = type_key.begins_with("boss")
		if is_boss:
			# Duplicate config so per-placement overrides don't mutate the .tres
			var override_cfg: Resource = cfg.duplicate()
			if p.has("summon_interval"):
				override_cfg.summon_interval = p["summon_interval"]
			if p.has("summon_type"):
				override_cfg.summon_type = p["summon_type"]
			if p.has("max_summons"):
				override_cfg.max_summons = p["max_summons"]
			if p.has("invisible_on_time"):
				override_cfg.invisible_on_time = p["invisible_on_time"]
			if p.has("invisible_off_time"):
				override_cfg.invisible_off_time = p["invisible_off_time"]
			var boss := BossFireball.new()
			add_child(boss)
			boss.setup(override_cfg, pos, _wall_registry, level)
			boss.set_fireball_manager(self)
		else:
			var fb := Fireball.new()
			add_child(fb)
			fb.setup(cfg, pos, _wall_registry, level)


## Get all active fireball board positions (for Qix rule).
func get_fireball_positions() -> PackedVector2Array:
	var positions := PackedVector2Array()
	for child in get_children():
		var fb := child as Fireball
		if fb != null:
			positions.append(fb.board_position)
	return positions


## Check arm-fireball collisions against all active build operations.
func check_arm_collisions(active_builds_node: Node) -> void:
	# IronGenerator power-up: arms ignore fireballs
	if GameManager.power_up_manager.is_iron_active():
		return
	for child in get_children():
		var fb := child as Fireball
		if fb == null:
			continue
		for build_child in active_builds_node.get_children():
			var op := build_child as BuildOperation
			if op == null or op._is_finalized:
				continue
			var radius: float = fb.config.radius
			op.damage_arm_at(fb.board_position, radius + 0.1)


## Inter-fireball elastic collision detection + resolution.
func _physics_process(delta: float) -> void:
	var fireballs: Array[Fireball] = []
	for child in get_children():
		var fb := child as Fireball
		if fb != null:
			fireballs.append(fb)

	var n := fireballs.size()
	for i in n:
		for j in range(i + 1, n):
			var a := fireballs[i]
			var b := fireballs[j]
			var toi := GeometryCollisionUtils.swept_circle_toi(
				a.previous_position, a.velocity, a.config.radius,
				b.previous_position, b.velocity, b.config.radius,
				delta
			)
			if toi < 0.0:
				continue
			# Resolve elastic collision
			var new_vels := GeometryCollisionUtils.elastic_collision(
				a.board_position, a.velocity,
				b.board_position, b.velocity
			)
			a.velocity = new_vels[0]
			b.velocity = new_vels[1]
			# Separate overlapping fireballs
			var diff := a.board_position - b.board_position
			var dist := diff.length()
			var min_dist: float = a.config.radius + b.config.radius
			if dist < min_dist and dist > 0.001:
				var push := diff.normalized() * (min_dist - dist) * 0.5
				a.board_position += push
				b.board_position -= push
			GameEvents.fireball_collision.emit(a, b)


func _find_valid_spawn_position() -> Variant:
	for attempt in 20:
		var pos := Vector2(randf_range(-9.0, 9.0), randf_range(-9.0, 9.0))
		if _wall_registry.is_point_in_playable_area(pos):
			return pos
	return null


## Remove fireballs in claimed regions (they get trapped).
func remove_fireballs_in_claimed() -> void:
	for child in get_children():
		var fb := child as Fireball
		if fb == null:
			continue
		if not _wall_registry.is_point_in_playable_area(fb.board_position):
			fb.queue_free()


## Clear all fireballs (level transition).
func clear_all() -> void:
	for child in get_children():
		child.queue_free()
