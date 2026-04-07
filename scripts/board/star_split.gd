class_name StarSplit
## Splits a polygon region into sectors via star pattern from a center point.
## Core algorithm for territory claiming in Gals Panic.

const MIN_SECTOR_AREA := 0.01


## Split region into N sectors using center + endpoints on boundary.
## Returns array of new Region sectors, or empty if split impossible.
static func split_region_by_star(
	region: Region, center: Vector2, endpoints: PackedVector2Array
) -> Array[Region]:
	if endpoints.size() < 2:
		return []

	# 1. Compute parametric position for each endpoint on polygon boundary
	var pairs: Array[Dictionary] = []
	for i in endpoints.size():
		var param := GeometryUtils.find_boundary_parameter(endpoints[i], region.polygon)
		pairs.append({"param": param, "point": endpoints[i]})

	# 2. Sort by parametric position (CCW order along boundary)
	pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["param"] < b["param"]
	)

	# 3. Remove near-duplicate parametric positions
	var filtered: Array[Dictionary] = [pairs[0]]
	for i in range(1, pairs.size()):
		if absf(pairs[i]["param"] - filtered.back()["param"]) > GeometryUtils.EPSILON:
			filtered.append(pairs[i])
	if filtered.size() < 2:
		return []

	# 4. For each consecutive pair, build sector polygon
	#    Use actual endpoint positions (not interpolated) to ensure watertight sectors
	var sectors: Array[Region] = []
	for i in filtered.size():
		var next_i := (i + 1) % filtered.size()
		var ep_start: Vector2 = filtered[i]["point"]
		var ep_end: Vector2 = filtered[next_i]["point"]

		# Walk boundary between the two parametric positions
		var boundary_verts := GeometryUtils.walk_boundary(
			region.polygon,
			filtered[i]["param"],
			filtered[next_i]["param"]
		)

		# Build sector polygon: ep_start → interior boundary verts → ep_end → center
		var sector_poly := PackedVector2Array()
		sector_poly.append(ep_start)

		# Add interior boundary vertices (skip first and last from walk,
		# as those are interpolated — we use exact endpoints instead)
		if boundary_verts.size() > 2:
			for vi in range(1, boundary_verts.size() - 1):
				sector_poly.append(boundary_verts[vi])

		sector_poly.append(ep_end)
		sector_poly.append(center)

		# Ensure CCW winding
		if GeometryUtils.signed_polygon_area(sector_poly) < 0.0:
			sector_poly.reverse()

		# Discard degenerate sectors
		if GeometryUtils.polygon_area(sector_poly) < MIN_SECTOR_AREA:
			continue

		var new_region := Region.new(sector_poly, false)
		sectors.append(new_region)

	return sectors


## Insert wall as spike into region boundary (fallback when split fails).
## Makes the wall traversable for future splits.
static func insert_wall_spike(
	region: Region, boundary_pt: Vector2, inner_pt: Vector2
) -> Region:
	var polygon := region.polygon
	var n := polygon.size()

	# Find closest edge to boundary_pt
	var best_edge := -1
	var best_dist := INF
	for i in n:
		var next_i := (i + 1) % n
		var dist := GeometryUtils.point_to_segment_distance(
			boundary_pt, polygon[i], polygon[next_i]
		)
		if dist < best_dist:
			best_dist = dist
			best_edge = i

	if best_edge < 0:
		return region

	# Build new polygon with spike inserted after best_edge vertex
	var new_poly := PackedVector2Array()
	for i in n:
		new_poly.append(polygon[i])
		if i == best_edge:
			new_poly.append(boundary_pt)
			new_poly.append(inner_pt)
			new_poly.append(boundary_pt)

	var new_region := Region.new(new_poly, region.is_claimed)
	return new_region
