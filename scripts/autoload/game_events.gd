extends Node

# Board / Wall events
signal wall_completed(operation_data: Dictionary)
signal wall_segment_registered(segment: RefCounted)
signal regions_claimed(regions: Array)
signal regions_claimed_with_data(claimed: Array, all_regions: Array)

# Scoring / Progress
signal claim_percentage_changed(percentage: float)
signal level_complete(level_index: int)
signal coins_changed(total: int)

# Life / Game state
signal life_lost()
signal lives_changed(current: int)
signal game_over()

# Generator / Inventory
signal generator_changed(type: int)
signal inventory_changed(type: int, count: int)
signal drop_item_collected(type: int)

# Wall placement / Arms
signal wall_placement_started()
signal wall_placement_cancelled()
signal drag_started()
signal arm_destroyed()
signal generator_destroyed()

# Wall destruction (boss mechanics)
signal wall_segment_destroyed(segment: RefCounted)
signal region_unclaimed(region: RefCounted)

# Fireballs
signal fireball_bounced(fireball: Node, hit_point: Vector2)
signal fireball_collision(a: Node, b: Node)

# UI / System
signal game_paused()
signal game_resumed()
signal timer_changed(remaining: float, total: float)
signal transition_started()
signal transition_ended()
signal tutorial_completed()

# Power-ups
signal power_up_changed(type: int)
signal power_up_build_state_changed(locked: bool)
