class_name TerritoryClaimer
extends RefCounted
## Orchestrates territory claiming: star-split + Qix rule + signal emission.


## Main entry point. Called when a wall build operation completes.
## fireball_positions: current positions of all active fireballs (empty if none).
func claim_territory(
	wall_registry: WallRegistry,
	generator_pos: Vector2,
	completed_endpoints: PackedVector2Array,
	fireball_positions: PackedVector2Array
) -> void:
	# 1. Find unclaimed region containing generator
	var region := wall_registry.find_region_containing(generator_pos)
	if region == null:
		return

	# 2. Star-split the region
	var sectors := StarSplit.split_region_by_star(region, generator_pos, completed_endpoints)

	# 3. Spike fallback: if split failed, insert wall as spike
	if sectors.size() <= 1 and completed_endpoints.size() >= 1:
		var spike := StarSplit.insert_wall_spike(
			region, completed_endpoints[0], generator_pos
		)
		var spike_arr: Array[Region] = [spike]
		wall_registry.replace_region(region, spike_arr)
		return

	if sectors.is_empty():
		return

	# 4. Qix Rule: decide which sectors to claim
	var to_claim: Array[Region] = []
	var to_keep: Array[Region] = []
	_apply_qix_rule(sectors, fireball_positions, to_claim, to_keep)

	# 5. Replace region in registry
	var all_new: Array[Region] = []
	all_new.append_array(to_claim)
	all_new.append_array(to_keep)
	wall_registry.replace_region(region, all_new)

	# 6. Emit signals
	if to_claim.size() > 0:
		var pct := wall_registry.get_claim_percentage()
		GameEvents.claim_percentage_changed.emit(pct)


## Apply Qix rule: claim sectors without fireballs.
## If no fireballs, claim all except the largest sector.
func _apply_qix_rule(
	sectors: Array[Region],
	fireball_positions: PackedVector2Array,
	to_claim: Array[Region],
	to_keep: Array[Region]
) -> void:
	if fireball_positions.size() > 0:
		# Claim sectors that contain NO fireballs
		for sector in sectors:
			var has_fireball := false
			for fb_pos in fireball_positions:
				if sector.contains_point(fb_pos):
					has_fireball = true
					break
			if has_fireball:
				to_keep.append(sector)
			else:
				sector.is_claimed = true
				to_claim.append(sector)
	else:
		# No fireballs: claim all except largest
		var largest_idx := 0
		var largest_area := 0.0
		for i in sectors.size():
			var area := sectors[i].get_area()
			if area > largest_area:
				largest_area = area
				largest_idx = i
		for i in sectors.size():
			if i == largest_idx:
				to_keep.append(sectors[i])
			else:
				sectors[i].is_claimed = true
				to_claim.append(sectors[i])
