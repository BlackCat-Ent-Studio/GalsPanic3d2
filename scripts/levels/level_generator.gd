class_name LevelGenerator
extends RefCounted
## Procedural level config generation. Zone-based difficulty scaling.


static func generate(level_index: int) -> LevelConfig:
	# Check for hand-crafted level first
	var crafted := _try_load_crafted(level_index)
	if crafted:
		return crafted
	# Fall back to procedural generation
	var config := LevelConfig.new()
	config.level_number = level_index + 1
	var zone: int = level_index / 5

	# Claim % to win: 50% → 95%
	config.claim_percentage_to_win = clampf(0.5 + zone * 0.05, 0.5, 0.95)

	# Time limit: generous early, tighter later
	config.time_limit_seconds = maxf(60.0, 180.0 - zone * 15.0)

	# Coins per excess cell
	config.coins_per_excess_cell = 1.0 + zone * 0.5

	# Fireball count: zone-scaled with boss bonus
	var base_min: int = 1 + zone
	var base_max: int = 4 + zone * 2
	var count: int = randi_range(base_min, base_max)
	var is_boss: bool = (level_index + 1) % 5 == 0
	if is_boss:
		count += 1

	# Effective speed level for fireball scaling
	var speed_level: int
	if zone == 0:
		speed_level = level_index
	elif zone == 1:
		speed_level = level_index + 1
	else:
		speed_level = level_index + zone

	config.fireball_spawn_entries = _generate_fireball_entries(level_index, count, speed_level)
	return config


static func _generate_fireball_entries(level_index: int, total: int, speed_level: int) -> Array:
	var entries: Array = []
	# Levels 0-4: Red only. 5-9: Red+Yellow. 10+: All three
	var available: Array[String] = ["red"]
	if level_index >= 5:
		available.append("yellow")
	if level_index >= 10:
		available.append("white")

	# Distribute fireballs round-robin across available types
	for i in total:
		var type_key: String = available[i % available.size()]
		var found := false
		for entry: Dictionary in entries:
			if entry["type"] == type_key:
				entry["count"] = entry["count"] + 1
				found = true
				break
		if not found:
			entries.append({"type": type_key, "count": 1, "speed_level": speed_level})

	return entries


## Try loading a hand-crafted level .tres file for this index.
static func _try_load_crafted(level_index: int) -> LevelConfig:
	var path := "res://resources/levels/level_%02d.tres" % (level_index + 1)
	if ResourceLoader.exists(path):
		var res: Resource = ResourceLoader.load(path)
		if res is LevelConfig:
			return res
	return null
