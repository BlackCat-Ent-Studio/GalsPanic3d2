class_name FireballConfig
extends Resource
## Configuration for a fireball type: movement pattern, speed, visuals, scaling.

enum Pattern { STRAIGHT, CURVE, ZIGZAG }

@export var pattern: Pattern = Pattern.STRAIGHT
@export var display_name: String = "Fireball"
@export var base_speed: float = 3.0
@export var radius: float = 0.25
@export var color: Color = Color.RED

# Curve-specific
@export var curve_radius: float = 3.0
@export var curve_ccw: bool = false

# Zigzag-specific
@export var zigzag_interval: float = 1.0
@export var zigzag_angle: float = 45.0

# Level scaling multipliers
@export var speed_scale_per_level: float = 0.05
@export var curve_radius_scale: float = -0.1
@export var zigzag_interval_scale: float = -0.03
