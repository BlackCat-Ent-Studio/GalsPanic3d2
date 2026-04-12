extends Node3D
class_name ScreenCrackEffect
## Layered broken screen effect: animated LCD glitch + broken glass texture overlay.

const CRACK_SIZE := 2.5
const FADE_DURATION := 2.0


## Spawn crack at a 3D position on the screen surface.
func setup(hit_position: Vector3) -> void:
	# Position the whole effect slightly in front of the screen
	global_position = hit_position + Vector3(0.0, 0.0, 0.02)

	# Layer 1 (back): animated LCD glitch shader
	var glitch_quad := MeshInstance3D.new()
	var glitch_mesh := QuadMesh.new()
	glitch_mesh.size = Vector2(CRACK_SIZE, CRACK_SIZE)
	glitch_quad.mesh = glitch_mesh
	var glitch_shader := preload("res://shaders/lcd_glitch.gdshader")
	var glitch_mat := ShaderMaterial.new()
	glitch_mat.shader = glitch_shader
	glitch_mat.set_shader_parameter("fade", 1.0)
	glitch_mat.set_shader_parameter("time_offset", randf() * 100.0)
	glitch_quad.material_override = glitch_mat
	add_child(glitch_quad)

	# Layer 2 (front): broken glass texture overlay
	var glass_quad := MeshInstance3D.new()
	var glass_mesh := QuadMesh.new()
	glass_mesh.size = Vector2(CRACK_SIZE, CRACK_SIZE)
	glass_quad.mesh = glass_mesh
	var tex: Texture2D = preload("res://textures/broken_glass.png")
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_texture = tex
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	glass_quad.material_override = glass_mat
	# Slightly forward of glitch layer
	glass_quad.position = Vector3(0.0, 0.0, 0.01)
	add_child(glass_quad)

	# Fade out both layers and self-destruct
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(glitch_mat, "shader_parameter/fade", 0.0, FADE_DURATION)
	tween.tween_property(glass_mat, "albedo_color:a", 0.0, FADE_DURATION)
	tween.chain().tween_callback(queue_free)
