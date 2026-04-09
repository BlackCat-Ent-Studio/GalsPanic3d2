extends GPUParticles3D
class_name FireballTrail
## Colored trail particles attached to fireball. Uses process material.


func setup(color: Color) -> void:
	amount = 16
	lifetime = 0.4
	one_shot = false
	emitting = true
	local_coords = false

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = 0.2
	mat.initial_velocity_max = 0.5
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.08
	mat.scale_max = 0.15
	mat.color = color

	# Fade out over lifetime
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color, 1.0))
	gradient.set_color(1, Color(color, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex

	process_material = mat

	# Simple quad mesh for particles
	var quad := QuadMesh.new()
	quad.size = Vector2(0.1, 0.1)
	draw_pass_1 = quad
