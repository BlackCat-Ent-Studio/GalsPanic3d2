extends MeshInstance3D
class_name ImageRevealScreen
## Vertical screen behind board (wall-mounted). Image revealed by claim mask.
## Unclaimed areas show opaque overlay. Claimed areas reveal the image.

const SCREEN_WIDTH := 20.0   # Same width as board
const SCREEN_HEIGHT := 12.0  # Shorter than wide (monitor ratio)
const SCREEN_Y_CENTER := 6.5  # Just above board back edge
const SCREEN_Z := -10.0  # At the board's back edge

var _shader_mat: ShaderMaterial
var _placeholder_texture: ImageTexture


func _ready() -> void:
	_create_mesh()
	_create_shader()


func _create_mesh() -> void:
	# QuadMesh is inherently vertical (XY plane), facing +Z (toward camera)
	var quad := QuadMesh.new()
	quad.size = Vector2(SCREEN_WIDTH, SCREEN_HEIGHT)
	mesh = quad
	# Position: standing at back edge of board, facing toward camera
	position = Vector3(0, SCREEN_Y_CENTER, SCREEN_Z)


func _create_shader() -> void:
	var shader := preload("res://shaders/image_reveal.gdshader")
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = shader
	_shader_mat.set_shader_parameter("grid_origin", Vector2(-10.0, -10.0))
	_shader_mat.set_shader_parameter("grid_size", Vector2(SCREEN_WIDTH, SCREEN_HEIGHT))
	# Placeholder gradient until real images added
	_placeholder_texture = _generate_placeholder()
	_shader_mat.set_shader_parameter("level_image", _placeholder_texture)
	material_override = _shader_mat


## Set the claim mask texture (same one used by ground shader).
func set_claim_mask(mask_texture: ImageTexture) -> void:
	_shader_mat.set_shader_parameter("claim_mask", mask_texture)


## Set level image. Pass null to use placeholder.
func set_level_image(texture: Texture2D) -> void:
	if texture:
		_shader_mat.set_shader_parameter("level_image", texture)
	else:
		_shader_mat.set_shader_parameter("level_image", _placeholder_texture)


## Set overlay color (the opaque color hiding the image).
func set_overlay_color(color: Color) -> void:
	_shader_mat.set_shader_parameter("overlay_color", color)


## Generate a colorful gradient placeholder image.
func _generate_placeholder() -> ImageTexture:
	var size := 256
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var u := float(x) / size
			var v := float(y) / size
			# Colorful gradient pattern
			var r := 0.5 + 0.5 * sin(u * TAU * 2.0)
			var g := 0.5 + 0.5 * sin(v * TAU * 2.0 + 2.0)
			var b := 0.5 + 0.5 * sin((u + v) * TAU + 4.0)
			img.set_pixel(x, y, Color(r, g, b))
	return ImageTexture.create_from_image(img)
