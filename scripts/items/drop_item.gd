extends Node3D
class_name DropItem
## Floating pickup that grants generator stock when collected via territory claim.

var item_type: int = 0  # GeneratorInventory.TYPE_UP_DOWN or TYPE_LEFT_RIGHT
var board_position: Vector2 = Vector2.ZERO
var lifetime: float = 8.0

var _time_alive: float = 0.0
var _flash_start: float = 6.0
var _mesh: MeshInstance3D


func setup(type: int, pos: Vector2) -> void:
	item_type = type
	board_position = pos
	position = Board.board_to_world(pos, 0.3)
	_create_visual()


func _create_visual() -> void:
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.35, 0.35, 0.35)
	_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.CYAN if item_type == GeneratorInventory.TYPE_UP_DOWN else Color.GREEN_YELLOW
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.5
	mat.emission_energy_multiplier = 0.8
	_mesh.material_override = mat
	add_child(_mesh)


func _process(delta: float) -> void:
	_time_alive += delta
	# Bob animation
	position.y = 0.3 + sin(_time_alive * 3.0) * 0.1
	# Rotate
	_mesh.rotation.y += delta * 2.0
	# Flash warning before expiry
	if _time_alive > _flash_start:
		visible = fmod(_time_alive, 0.3) < 0.15
	# Expire
	if _time_alive >= lifetime:
		queue_free()
