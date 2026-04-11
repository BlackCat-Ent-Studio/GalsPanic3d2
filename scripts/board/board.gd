extends Node3D
class_name Board
## Board node: initializes wall registry, ground mesh with claim shader, claim tiles.

const BOUNDS_MIN := Vector2(-10.0, -10.0)
const BOUNDS_MAX := Vector2(10.0, 10.0)
const BOARD_SIZE := 20.0

var wall_registry: WallRegistry
var claim_texture: ClaimTexture
var territory_claimer: TerritoryClaimer

var _ground_shader_mat: ShaderMaterial
var _claim_tile_spawner: ClaimTileSpawner
var _reveal_screen: ImageRevealScreen


func _ready() -> void:
	wall_registry = WallRegistry.new()
	wall_registry.initialize_board(BOUNDS_MIN, BOUNDS_MAX)
	claim_texture = ClaimTexture.new()
	territory_claimer = TerritoryClaimer.new()
	_create_ground_mesh()
	_create_claim_tile_spawner()
	_create_reveal_screen()
	# Initial texture render
	claim_texture.regenerate(wall_registry.regions, wall_registry.segments)
	# Listen for claim events and wall destruction to regenerate texture
	GameEvents.regions_claimed_with_data.connect(_on_regions_claimed)
	GameEvents.wall_segment_destroyed.connect(_on_segment_destroyed)
	GameEvents.region_unclaimed.connect(_on_region_unclaimed)


func _create_ground_mesh() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(BOARD_SIZE, BOARD_SIZE)
	mesh_instance.mesh = plane

	# Claim shader material
	var shader := preload("res://shaders/ground_claim.gdshader")
	_ground_shader_mat = ShaderMaterial.new()
	_ground_shader_mat.shader = shader
	_ground_shader_mat.set_shader_parameter("claim_mask", claim_texture.get_texture())
	_ground_shader_mat.set_shader_parameter("grid_origin", BOUNDS_MIN)
	_ground_shader_mat.set_shader_parameter("grid_size", Vector2(BOARD_SIZE, BOARD_SIZE))
	mesh_instance.material_override = _ground_shader_mat

	add_child(mesh_instance)


func _create_claim_tile_spawner() -> void:
	_claim_tile_spawner = ClaimTileSpawner.new()
	_claim_tile_spawner.name = "ClaimTiles"
	add_child(_claim_tile_spawner)


func _create_reveal_screen() -> void:
	_reveal_screen = ImageRevealScreen.new()
	_reveal_screen.name = "RevealScreen"
	add_child(_reveal_screen)
	_reveal_screen.set_claim_mask(claim_texture.get_texture())


func _on_regions_claimed(_claimed: Array, _all: Array) -> void:
	claim_texture.regenerate(wall_registry.regions, wall_registry.segments)


func _on_segment_destroyed(_segment: RefCounted) -> void:
	claim_texture.regenerate(wall_registry.regions, wall_registry.segments)


func _on_region_unclaimed(_region: RefCounted) -> void:
	claim_texture.regenerate(wall_registry.regions, wall_registry.segments)


## Force a texture refresh (called externally if needed).
func refresh_claim_texture() -> void:
	claim_texture.regenerate(wall_registry.regions, wall_registry.segments)


## Set the level image for the reveal screen. Pass null for placeholder.
func set_level_image(texture: Texture2D) -> void:
	if _reveal_screen:
		_reveal_screen.set_level_image(texture)


## Convert board 2D coords (XZ) to 3D world position.
static func board_to_world(pos_2d: Vector2, y: float = 0.0) -> Vector3:
	return Vector3(pos_2d.x, y, pos_2d.y)


## Convert 3D world position to board 2D coords (XZ).
static func world_to_board(pos_3d: Vector3) -> Vector2:
	return Vector2(pos_3d.x, pos_3d.z)
