extends Node3D
class_name ClaimTileSpawner
## Spawns 3D extruded prism tiles that rise from underground when territory claimed.

const TILE_HEIGHT := 0.12
const RISE_SPEED := 2.0
const EDGE_EXPAND := 0.03  # Slight polygon expansion to cover seams

var _rising_tiles: Array[Dictionary] = []
var _tile_material: StandardMaterial3D


func _ready() -> void:
	_tile_material = StandardMaterial3D.new()
	_tile_material.albedo_color = Color(0.25, 0.55, 0.9)
	_tile_material.emission_enabled = true
	_tile_material.emission = Color(0.1, 0.25, 0.5)
	_tile_material.emission_energy_multiplier = 0.3
	GameEvents.regions_claimed_with_data.connect(_on_regions_claimed)


func _process(delta: float) -> void:
	# Animate rising tiles
	var i := _rising_tiles.size() - 1
	while i >= 0:
		var entry: Dictionary = _rising_tiles[i]
		entry["progress"] = entry["progress"] + delta * RISE_SPEED
		var t: float = minf(entry["progress"], 1.0)
		# Ease-out: 1 - (1-t)^2
		var eased := 1.0 - (1.0 - t) * (1.0 - t)
		var node: MeshInstance3D = entry["node"]
		node.position.y = lerpf(-TILE_HEIGHT, 0.0, eased)
		if t >= 1.0:
			_rising_tiles.remove_at(i)
		i -= 1
	if _rising_tiles.is_empty():
		set_process(false)


func _on_regions_claimed(claimed: Array, _all_regions: Array) -> void:
	for region_variant: Variant in claimed:
		var region: Region = region_variant as Region
		if region == null:
			continue
		_spawn_tile(region)
	set_process(true)


func _spawn_tile(region: Region) -> void:
	# Slightly expand polygon outward to cover seams between sectors
	var expanded := _expand_polygon(region.polygon, EDGE_EXPAND)
	var mesh := _generate_prism_mesh(expanded)
	if mesh == null:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _tile_material
	mi.position.y = -TILE_HEIGHT
	add_child(mi)
	_rising_tiles.append({"node": mi, "progress": 0.0})


func _generate_prism_mesh(polygon: PackedVector2Array) -> ArrayMesh:
	if polygon.size() < 3:
		return null

	# Triangulate top face using Godot built-in
	var indices := Geometry2D.triangulate_polygon(polygon)
	if indices.is_empty():
		return null

	var mesh := ArrayMesh.new()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var idx_array := PackedInt32Array()

	# Top face
	var base_idx := 0
	for v in polygon:
		verts.append(Vector3(v.x, TILE_HEIGHT, v.y))
		normals.append(Vector3.UP)
	for tri_idx in indices:
		idx_array.append(base_idx + tri_idx)

	# Bottom face (reversed winding)
	base_idx = verts.size()
	for v in polygon:
		verts.append(Vector3(v.x, 0.0, v.y))
		normals.append(Vector3.DOWN)
	for i in range(0, indices.size(), 3):
		idx_array.append(base_idx + indices[i + 2])
		idx_array.append(base_idx + indices[i + 1])
		idx_array.append(base_idx + indices[i])

	# Side faces
	var n := polygon.size()
	for i in n:
		var next_i := (i + 1) % n
		var a2 := polygon[i]
		var b2 := polygon[next_i]

		var top_a := Vector3(a2.x, TILE_HEIGHT, a2.y)
		var top_b := Vector3(b2.x, TILE_HEIGHT, b2.y)
		var bot_a := Vector3(a2.x, 0.0, a2.y)
		var bot_b := Vector3(b2.x, 0.0, b2.y)

		# Outward normal (XZ plane)
		var edge := Vector2(b2.x - a2.x, b2.y - a2.y)
		var side_normal := Vector3(edge.y, 0.0, -edge.x).normalized()

		base_idx = verts.size()
		verts.append(top_a); normals.append(side_normal)
		verts.append(top_b); normals.append(side_normal)
		verts.append(bot_b); normals.append(side_normal)
		verts.append(bot_a); normals.append(side_normal)

		idx_array.append(base_idx)
		idx_array.append(base_idx + 1)
		idx_array.append(base_idx + 2)
		idx_array.append(base_idx)
		idx_array.append(base_idx + 2)
		idx_array.append(base_idx + 3)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = idx_array
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Expand polygon outward from centroid by amount. Covers seams between sectors.
func _expand_polygon(polygon: PackedVector2Array, amount: float) -> PackedVector2Array:
	if polygon.size() < 3:
		return polygon
	# Find centroid
	var centroid := Vector2.ZERO
	for v in polygon:
		centroid += v
	centroid /= float(polygon.size())
	# Push each vertex slightly away from centroid
	var result := PackedVector2Array()
	for v: Vector2 in polygon:
		var dir := (v - centroid).normalized()
		result.append(v + dir * amount)
	return result
