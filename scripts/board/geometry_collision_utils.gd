class_name GeometryCollisionUtils
## Collision-specific geometry: swept circle TOI, segment-circle tests.

const EPSILON := 1e-6


## Swept circle time-of-impact. Two circles moving linearly over dt.
## Returns earliest touch time in [0, dt], or -1.0 if no collision.
static func swept_circle_toi(
	pos_a: Vector2, vel_a: Vector2, radius_a: float,
	pos_b: Vector2, vel_b: Vector2, radius_b: float,
	dt: float
) -> float:
	# Relative motion: treat A as stationary, B moves with relative velocity
	var rel_pos := pos_b - pos_a
	var rel_vel := vel_b - vel_a
	var combined_r := radius_a + radius_b

	# Quadratic: |rel_pos + rel_vel * t|^2 = combined_r^2
	var a := rel_vel.dot(rel_vel)
	var b := 2.0 * rel_pos.dot(rel_vel)
	var c := rel_pos.dot(rel_pos) - combined_r * combined_r

	# Already overlapping
	if c < 0.0:
		return 0.0

	# No relative movement
	if a < EPSILON:
		return -1.0

	var discriminant := b * b - 4.0 * a * c
	if discriminant < 0.0:
		return -1.0

	var sqrt_d := sqrt(discriminant)
	var t := (-b - sqrt_d) / (2.0 * a)

	if t >= -EPSILON and t <= dt + EPSILON:
		return clampf(t, 0.0, dt)
	return -1.0


## Check if a moving circle hits a static line segment.
## Returns {time: float, point: Vector2} or empty dict.
static func swept_circle_segment(
	circle_pos: Vector2, circle_vel: Vector2, radius: float,
	seg_a: Vector2, seg_b: Vector2, dt: float
) -> Dictionary:
	var seg_dir := seg_b - seg_a
	var seg_len := seg_dir.length()
	if seg_len < EPSILON:
		return {}
	var seg_normal := Vector2(-seg_dir.y, seg_dir.x) / seg_len

	# Distance from circle center to infinite line
	var dist := (circle_pos - seg_a).dot(seg_normal)
	var vel_toward := circle_vel.dot(seg_normal)

	# Moving away or parallel
	if absf(vel_toward) < EPSILON:
		if absf(dist) > radius:
			return {}
		return {}

	# Time to reach radius distance from line
	var t_enter: float
	if dist > 0.0:
		t_enter = (dist - radius) / -vel_toward if vel_toward < 0.0 else -1.0
	else:
		t_enter = (-dist - radius) / vel_toward if vel_toward > 0.0 else -1.0

	if t_enter < -EPSILON or t_enter > dt + EPSILON:
		return {}

	t_enter = clampf(t_enter, 0.0, dt)

	# Check if hit point is within segment bounds
	var hit_center := circle_pos + circle_vel * t_enter
	var proj := (hit_center - seg_a).dot(seg_dir) / (seg_len * seg_len)
	if proj < -EPSILON or proj > 1.0 + EPSILON:
		return {}

	var contact := seg_a + seg_dir * clampf(proj, 0.0, 1.0)
	return {"time": t_enter, "point": contact}


## Reflect a velocity vector off a wall segment.
static func reflect_off_segment(velocity: Vector2, seg_a: Vector2, seg_b: Vector2) -> Vector2:
	var seg_dir := seg_b - seg_a
	var normal := Vector2(-seg_dir.y, seg_dir.x).normalized()
	# Ensure normal points toward the incoming direction
	if velocity.dot(normal) > 0.0:
		normal = -normal
	return velocity.bounce(normal)


## Elastic collision between two equal-mass circles.
## Returns [new_vel_a, new_vel_b].
static func elastic_collision(
	pos_a: Vector2, vel_a: Vector2,
	pos_b: Vector2, vel_b: Vector2
) -> Array[Vector2]:
	var diff := pos_a - pos_b
	var dist_sq := diff.length_squared()
	if dist_sq < EPSILON:
		return [vel_a, vel_b]
	var dv_a := vel_a - vel_b
	var new_vel_a := vel_a - dv_a.dot(diff) / dist_sq * diff
	var dv_b := vel_b - vel_a
	var new_vel_b := vel_b - dv_b.dot(-diff) / dist_sq * (-diff)
	return [new_vel_a, new_vel_b]
