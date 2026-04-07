class_name WallRegistry
extends RefCounted
## Central board state: all walls and regions. Single source of truth.

var segments: Array[WallSegment] = []
var regions: Array[Region] = []
var bounds_min: Vector2
var bounds_max: Vector2


## Create 4 boundary segments and 1 full-board unclaimed region (CCW).
func initialize_board(p_bounds_min: Vector2, p_bounds_max: Vector2) -> void:
	bounds_min = p_bounds_min
	bounds_max = p_bounds_max
	segments.clear()
	regions.clear()

	# 4 corners
	var bl := bounds_min
	var br := Vector2(bounds_max.x, bounds_min.y)
	var tr := bounds_max
	var tl := Vector2(bounds_min.x, bounds_max.y)

	# Boundary segments (clockwise edges, but region polygon is CCW)
	segments.append(WallSegment.new(bl, br, true))
	segments.append(WallSegment.new(br, tr, true))
	segments.append(WallSegment.new(tr, tl, true))
	segments.append(WallSegment.new(tl, bl, true))

	# Initial region: full board, CCW winding
	var poly := PackedVector2Array([bl, br, tr, tl])
	var initial_region := Region.new(poly, false)
	initial_region.ensure_ccw()
	regions.append(initial_region)


func add_segment(segment: WallSegment) -> void:
	segments.append(segment)
	GameEvents.wall_segment_registered.emit(segment)


## Raycast from origin in direction against all segments.
## Returns {point, segment, distance} for nearest hit, or empty dict.
func raycast_to_wall(origin: Vector2, direction: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_t := INF
	for seg in segments:
		var result := GeometryUtils.ray_segment_intersection(origin, direction, seg.start, seg.end)
		if result.is_empty():
			continue
		var t: float = result["t"]
		if t > GeometryUtils.EPSILON and t < best_t:
			best_t = t
			best = {"point": result["point"], "segment": seg, "distance": t}
	return best


## Find first unclaimed region containing point.
func find_region_containing(point: Vector2) -> Region:
	for region in regions:
		if not region.is_claimed and region.contains_point(point):
			return region
	return null


## True if point is inside any unclaimed region.
func is_point_in_playable_area(point: Vector2) -> bool:
	return find_region_containing(point) != null


## Claimed area / total area.
func get_claim_percentage() -> float:
	var claimed_area := 0.0
	var total_area := 0.0
	for region in regions:
		var a := region.get_area()
		total_area += a
		if region.is_claimed:
			claimed_area += a
	if total_area < GeometryUtils.EPSILON:
		return 0.0
	return claimed_area / total_area


## Remove old_region, insert new_regions in its place.
func replace_region(old_region: Region, new_regions: Array[Region]) -> void:
	var idx := regions.find(old_region)
	if idx < 0:
		return
	regions.remove_at(idx)
	for i in new_regions.size():
		regions.insert(idx + i, new_regions[i])
	GameEvents.regions_claimed_with_data.emit(
		new_regions.filter(func(r: Region) -> bool: return r.is_claimed),
		regions
	)


## Get all unclaimed regions.
func get_unclaimed_regions() -> Array[Region]:
	var result: Array[Region] = []
	for region in regions:
		if not region.is_claimed:
			result.append(region)
	return result


## Total board area (bounds).
func get_total_area() -> float:
	var size := bounds_max - bounds_min
	return size.x * size.y
