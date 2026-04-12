extends MeshInstance3D
class_name ScreenCrackEffect
## Broken glass texture overlay on image reveal screen. Fades and self-destructs.

const CRACK_SIZE := 2.5
const FADE_DURATION := 2.0


## Spawn crack at a 3D position on the screen surface.
func setup(hit_position: Vector3) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(CRACK_SIZE, CRACK_SIZE)
	mesh = quad

	var tex: Texture2D = preload("res://textures/broken_glass.png")
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	material_override = mat

	# Position slightly in front of screen to avoid z-fighting
	global_position = hit_position + Vector3(0.0, 0.0, 0.02)

	# Fade out and self-destruct
	var tween := create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, FADE_DURATION)
	tween.tween_callback(queue_free)
