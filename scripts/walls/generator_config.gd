class_name GeneratorConfig
extends Resource
## Configuration for a wall generator type. Defines arm directions, speed, etc.

enum Type { CROSS4, UP_DOWN, LEFT_RIGHT }

@export var type: Type = Type.CROSS4
@export var display_name: String = "Cross"
@export var arms: Array[Vector2] = []
@export var build_speed: float = 5.0
@export var preview_color: Color = Color(0.3, 0.8, 1.0, 0.5)
@export var is_unlimited: bool = true

## Wall visual color when completed
@export var wall_color: Color = Color(0.9, 0.9, 0.95)
