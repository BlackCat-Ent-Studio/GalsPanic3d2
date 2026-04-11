class_name LevelConfig
extends Resource
## Configuration for a single game level.

@export var level_number: int = 1
@export var claim_percentage_to_win: float = 0.5
@export var time_limit_seconds: float = 120.0
@export var coins_per_excess_cell: float = 1.0
## Array of {type: String, count: int, speed_level: int}
@export var fireball_spawn_entries: Array = []
## Array of {type: String, position: Vector2, speed: float, radius: float}
## If non-empty, these override fireball_spawn_entries with exact positions
@export var fireball_placements: Array = []
@export var claimed_tile_color: Color = Color(0.2, 0.6, 1.0)
