extends Node3D
class_name Board
## Board node: initializes wall registry, creates ground mesh, manages debug draw.

const BOUNDS_MIN := Vector2(-10.0, -10.0)
const BOUNDS_MAX := Vector2(10.0, 10.0)
const BOARD_SIZE := 20.0

var wall_registry: WallRegistry


func _ready() -> void:
	wall_registry = WallRegistry.new()
	wall_registry.initialize_board(BOUNDS_MIN, BOUNDS_MAX)
	_create_ground_mesh()


func _create_ground_mesh() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(BOARD_SIZE, BOARD_SIZE)
	mesh_instance.mesh = plane

	# Basic gray material for now (will be replaced by claim shader later)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.18, 0.22)
	mesh_instance.material_override = mat

	add_child(mesh_instance)


## Convert board 2D coords (XZ) to 3D world position.
static func board_to_world(pos_2d: Vector2, y: float = 0.0) -> Vector3:
	return Vector3(pos_2d.x, y, pos_2d.y)


## Convert 3D world position to board 2D coords (XZ).
static func world_to_board(pos_3d: Vector3) -> Vector2:
	return Vector2(pos_3d.x, pos_3d.z)
