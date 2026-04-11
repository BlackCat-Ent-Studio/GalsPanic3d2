extends MeshInstance3D
class_name ScreenCrackEffect
## Small procedural crack on image reveal screen. Fades and self-destructs.

const CRACK_SIZE := 2.5
const FADE_DURATION := 2.0


## Spawn crack at a 3D position on the screen surface.
func setup(hit_position: Vector3) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(CRACK_SIZE, CRACK_SIZE)
	mesh = quad

	var shader := preload("res://shaders/screen_crack.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("fade", 1.0)
	mat.set_shader_parameter("crack_color", Vector3(1.0, 1.0, 1.0))
	material_override = mat

	# Position slightly in front of screen to avoid z-fighting
	global_position = hit_position + Vector3(0.0, 0.0, 0.02)

	# Fade out and self-destruct
	var tween := create_tween()
	tween.tween_property(mat, "shader_parameter/fade", 0.0, FADE_DURATION)
	tween.tween_callback(queue_free)
