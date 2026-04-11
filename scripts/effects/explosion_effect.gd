extends Node3D
class_name ExplosionEffect
## Multi-layer explosion: flash, expanding ring, light fade. Self-destructs.

var _color: Color = Color(1.0, 0.5, 0.2)


func setup(pos: Vector3, color: Color = Color(1.0, 0.5, 0.2)) -> void:
	position = pos
	_color = color


func _ready() -> void:
	_create_flash()
	_create_ring()
	_create_light()
	# Self-destruct
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(queue_free)


func _create_flash() -> void:
	var mi := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.1, 0.1)
	mi.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color.WHITE
	mat.emission_enabled = true
	mat.emission = _color
	mat.emission_energy_multiplier = 5.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mi.material_override = mat
	add_child(mi)
	# Scale up fast, then fade
	var tween := create_tween()
	tween.tween_property(mi, "scale", Vector3(3, 3, 3), 0.1)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.4)


func _create_ring() -> void:
	var mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.3
	torus.outer_radius = 0.4
	mi.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color
	mat.emission_enabled = true
	mat.emission = _color
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	add_child(mi)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(mi, "scale", Vector3(4, 1, 4), 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.8)


func _create_light() -> void:
	var light := OmniLight3D.new()
	light.light_color = _color
	light.light_energy = 3.0
	light.omni_range = 5.0
	add_child(light)
	var tween := create_tween()
	tween.tween_property(light, "light_energy", 0.0, 1.0)
