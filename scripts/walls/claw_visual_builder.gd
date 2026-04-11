class_name ClawVisualBuilder
extends RefCounted
## Builds 3D meshes for the claw machine: hub body, prongs, held block.


## Central hub body of the claw — cylinder with metallic look.
static func create_hub() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 0.25
	cyl.height = 0.3
	mi.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.65, 0.7)
	mat.metallic = 0.7
	mat.roughness = 0.3
	mi.material_override = mat
	return mi


## A single curved prong. offset = position relative to hub, angle = initial grip angle.
static func create_prong(offset: Vector3, rot_axis: String, angle: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = offset

	# Upper segment (attached to hub)
	var upper := MeshInstance3D.new()
	var box_u := BoxMesh.new()
	box_u.size = Vector3(0.07, 0.25, 0.07)
	upper.mesh = box_u
	upper.position.y = -0.12
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.6, 0.65)
	mat.metallic = 0.6
	mat.roughness = 0.35
	upper.material_override = mat
	pivot.add_child(upper)

	# Lower tip (angled inward — the grabbing part)
	var tip := MeshInstance3D.new()
	var box_t := BoxMesh.new()
	box_t.size = Vector3(0.06, 0.18, 0.06)
	tip.mesh = box_t
	tip.position = Vector3(0, -0.3, 0)
	tip.rotation_degrees.z = -angle * 0.5 if rot_axis == "z" else 0.0
	tip.rotation_degrees.x = -angle * 0.5 if rot_axis == "x" else 0.0
	tip.material_override = mat
	pivot.add_child(tip)

	# Set initial grip rotation
	if rot_axis == "z":
		pivot.rotation_degrees.z = angle
	else:
		pivot.rotation_degrees.x = angle

	return pivot


## Generator block held by the claw.
static func create_block() -> Array:
	## Returns [MeshInstance3D, StandardMaterial3D]
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.45, 0.45, 0.45)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.8, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.4, 0.5)
	mat.emission_energy_multiplier = 0.6
	mi.material_override = mat
	mi.position.y = -0.55
	return [mi, mat]
