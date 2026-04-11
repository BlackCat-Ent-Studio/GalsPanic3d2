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

# Boss properties
@export var is_boss: bool = false
@export var boss_type: int = 0  # 0=none, 1=Tank(slow), 2=Ghost(invisible)
@export var summon_interval: float = 8.0  # seconds between summons
@export var summon_type: String = "red"  # type of mini to summon
@export var max_summons: int = 3  # max minis this boss can have alive
@export var invisible_on_time: float = 10.0  # Ghost: visible duration
@export var invisible_off_time: float = 5.0  # Ghost: invisible duration
