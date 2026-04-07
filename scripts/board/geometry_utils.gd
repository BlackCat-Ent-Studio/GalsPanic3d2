class_name GeometryUtils
## Core 2D geometry functions for board math. All static, no state.

const EPSILON := 1e-6


## Ray vs line segment intersection. Returns {point, t, u} or empty dict.
## t = distance along ray, u = parameter along segment [0,1].
static func ray_segment_intersection(origin: Vector2, direction: Vector2, seg_a: Vector2, seg_b: Vector2) -> Dictionary:
	var seg_dir := seg_b - seg_a
	var denom := direction.x * seg_dir.y - direction.y * seg_dir.x
	if absf(denom) < EPSILON:
		return {}
	var diff := seg_a - origin
	var t := (diff.x * seg_dir.y - diff.y * seg_dir.x) / denom
	var u := (diff.x * direction.y - diff.y * direction.x) / denom
	if t < -EPSILON or u < -EPSILON or u > 1.0 + EPSILON:
		return {}
	var point := origin + direction * t
	return {"point": point, "t": t, "u": u}


## Horizontal ray-cast point-in-polygon test. Odd crossings = inside.
static func point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var n := polygon.size()
	if n < 3:
		return false
	var inside := false
	var j := n - 1
	for i in n:
		var vi := polygon[i]
		var vj := polygon[j]
		if ((vi.y > point.y) != (vj.y > point.y)) and \
			(point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x):
			inside = not inside
		j = i
	return inside


## Signed polygon area via shoelace. Positive = CCW winding.
static func signed_polygon_area(polygon: PackedVector2Array) -> float:
	var n := polygon.size()
	if n < 3:
		return 0.0
	var area := 0.0
	var j := n - 1
	for i in n:
		area += polygon[j].x * polygon[i].y - polygon[i].x * polygon[j].y
		j = i
	return area * 0.5


## Unsigned polygon area.
static func polygon_area(polygon: PackedVector2Array) -> float:
	return absf(signed_polygon_area(polygon))


## Closest point on segment to a test point.
static func closest_point_on_segment(point: Vector2, seg_a: Vector2, seg_b: Vector2) -> Vector2:
	var ab := seg_b - seg_a
	var len_sq := ab.length_squared()
	if len_sq < EPSILON:
		return seg_a
	var t := clampf((point - seg_a).dot(ab) / len_sq, 0.0, 1.0)
	return seg_a + ab * t


## Distance from point to nearest point on segment.
static func point_to_segment_distance(point: Vector2, seg_a: Vector2, seg_b: Vector2) -> float:
	return point.distance_to(closest_point_on_segment(point, seg_a, seg_b))


## Parametric position [0, N) of point along polygon boundary.
## Edge i goes from vertex i to vertex (i+1)%N, parameter range [i, i+1).
static func find_boundary_parameter(point: Vector2, polygon: PackedVector2Array) -> float:
	var n := polygon.size()
	var best_param := 0.0
	var best_dist := INF
	for i in n:
		var a := polygon[i]
		var b := polygon[(i + 1) % n]
		var ab := b - a
		var len_sq := ab.length_squared()
		var t := 0.0
		if len_sq > EPSILON:
			t = clampf((point - a).dot(ab) / len_sq, 0.0, 1.0)
		var closest := a + ab * t
		var dist := point.distance_squared_to(closest)
		if dist < best_dist:
			best_dist = dist
			best_param = float(i) + t
	return best_param


## Walk polygon boundary from param_start to param_end (forward/wrapping).
## Returns collected vertices including interpolated start/end points.
static func walk_boundary(polygon: PackedVector2Array, param_start: float, param_end: float) -> PackedVector2Array:
	var n := polygon.size()
	var nf := float(n)
	var result := PackedVector2Array()
	# Normalize params
	var ps := fmod(param_start, nf)
	if ps < 0.0:
		ps += nf
	var pe := fmod(param_end, nf)
	if pe < 0.0:
		pe += nf
	# Interpolated start point
	var si := int(ps) % n
	var sf := ps - floorf(ps)
	var start_pt := polygon[si].lerp(polygon[(si + 1) % n], sf)
	result.append(start_pt)
	# Walk forward from ceil(param_start) to floor(param_end), wrapping
	var walk_len := pe - ps
	if walk_len <= EPSILON:
		walk_len += nf
	var current := ceilf(ps)
	if current - ps < EPSILON:
		current += 1.0
	var walked := current - ps
	while walked < walk_len - EPSILON:
		var idx := int(fmod(current, nf)) % n
		result.append(polygon[idx])
		current += 1.0
		walked = current - ps
	# Interpolated end point
	var ei := int(pe) % n
	var ef := pe - floorf(pe)
	var end_pt := polygon[ei].lerp(polygon[(ei + 1) % n], ef)
	result.append(end_pt)
	return result
