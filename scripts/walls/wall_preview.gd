extends Node3D
class_name WallPreview
## Shows translucent generator + arm path lines during drag preview.

var _generator_mesh: MeshInstance3D
var _arm_meshes: Array[MeshInstance3D] = []
var _preview_material: StandardMaterial3D
var _invalid_material: StandardMaterial3D


func _ready() -> void:
	visible = false
	_create_materials()
	_create_generator_mesh()


func _create_materials() -> void:
	_preview_material = StandardMaterial3D.new()
	_preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_preview_material.albedo_color = Color(0.3, 0.8, 1.0, 0.4)
	_preview_material.no_depth_test = true

	_invalid_material = StandardMaterial3D.new()
	_invalid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_invalid_material.albedo_color = Color(1.0, 0.2, 0.2, 0.4)
	_invalid_material.no_depth_test = true


func _create_generator_mesh() -> void:
	_generator_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	_generator_mesh.mesh = box
	_generator_mesh.material_override = _preview_material
	add_child(_generator_mesh)


func show_preview(board_pos: Vector2, config: Resource, registry: WallRegistry, is_valid: bool) -> void:
	visible = true
	position = Board.board_to_world(board_pos, 0.3)

	# Update generator color
	var mat := _preview_material if is_valid else _invalid_material
	_generator_mesh.material_override = mat
	if is_valid:
		_preview_material.albedo_color = Color(config.preview_color, 0.4)

	# Update arm preview lines
	_update_arm_previews(board_pos, config, registry, mat)


func hide_preview() -> void:
	visible = false


func _update_arm_previews(board_pos: Vector2, config: Resource, registry: WallRegistry, mat: Material) -> void:
	# Ensure correct number of arm meshes
	while _arm_meshes.size() < config.arms.size():
		var arm_mesh := MeshInstance3D.new()
		arm_mesh.mesh = BoxMesh.new()
		arm_mesh.material_override = mat
		add_child(arm_mesh)
		_arm_meshes.append(arm_mesh)

	# Hide excess arms
	for i in _arm_meshes.size():
		_arm_meshes[i].visible = i < config.arms.size()

	# Position each arm from generator to hit point
	for i in config.arms.size():
		var dir: Vector2 = config.arms[i]
		var hit := registry.raycast_to_wall(board_pos, dir)
		var arm_mi := _arm_meshes[i]
		arm_mi.material_override = mat

		if hit.is_empty():
			arm_mi.visible = false
			continue

		var end_2d: Vector2 = hit["point"]
		var length := board_pos.distance_to(end_2d)
		if length < 0.01:
			arm_mi.visible = false
			continue

		arm_mi.visible = true
		var mid_2d := (board_pos + end_2d) * 0.5
		# Arm mesh: thin box scaled along direction
		var box: BoxMesh = arm_mi.mesh
		box.size = Vector3(0.08, 0.08, length)
		# Position relative to parent (which is at board_pos)
		var local_mid := mid_2d - board_pos
		arm_mi.position = Vector3(local_mid.x, 0.0, local_mid.y)
		# Rotate to face direction
		var angle := atan2(dir.x, dir.y)
		arm_mi.rotation = Vector3(0.0, angle, 0.0)
