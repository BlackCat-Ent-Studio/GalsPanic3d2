extends Node3D
class_name DropItemSpawner
## Spawns drop items after wall placement. Collected when region claimed.

const MAX_ACTIVE := 3
const BASE_CHANCE := 0.35
const MIN_REGION_AREA := 0.5

var _wall_registry: WallRegistry
var _inventory: GeneratorInventory


func setup(registry: WallRegistry, inventory: GeneratorInventory) -> void:
	_wall_registry = registry
	_inventory = inventory
	GameEvents.wall_placement_started.connect(_on_wall_placed)
	GameEvents.regions_claimed_with_data.connect(_on_regions_claimed)


func _on_wall_placed() -> void:
	if get_child_count() >= MAX_ACTIVE:
		return
	var level: int = GameManager.current_level_index
	var chance := clampf(BASE_CHANCE - level * 0.015, 0.05, 0.30)
	if randf() > chance:
		return
	_spawn_drop()


func _spawn_drop() -> void:
	var valid_regions: Array[Region] = []
	for region in _wall_registry.get_unclaimed_regions():
		if region.get_area() > MIN_REGION_AREA:
			valid_regions.append(region)
	if valid_regions.is_empty():
		return

	var region: Region = valid_regions[randi() % valid_regions.size()]
	var pos: Variant = _rejection_sample(region)
	if pos == null:
		return

	var drop := DropItem.new()
	var type: int
	if randf() > 0.5:
		type = GeneratorInventory.TYPE_UP_DOWN
	else:
		type = GeneratorInventory.TYPE_LEFT_RIGHT
	add_child(drop)
	drop.setup(type, pos)


func _on_regions_claimed(_claimed: Array, _all: Array) -> void:
	for child in get_children():
		var drop := child as DropItem
		if drop == null or not is_instance_valid(drop):
			continue
		for region_v: Variant in _claimed:
			var region: Region = region_v as Region
			if region and region.contains_point(drop.board_position):
				_inventory.add_stock(drop.item_type, 1)
				GameEvents.drop_item_collected.emit(drop.item_type)
				drop.queue_free()
				break


func _rejection_sample(region: Region) -> Variant:
	var poly := region.polygon
	var min_p := poly[0]
	var max_p := poly[0]
	for v: Vector2 in poly:
		min_p = Vector2(minf(min_p.x, v.x), minf(min_p.y, v.y))
		max_p = Vector2(maxf(max_p.x, v.x), maxf(max_p.y, v.y))
	for attempt in 20:
		var pos := Vector2(randf_range(min_p.x, max_p.x), randf_range(min_p.y, max_p.y))
		if region.contains_point(pos):
			return pos
	return null
