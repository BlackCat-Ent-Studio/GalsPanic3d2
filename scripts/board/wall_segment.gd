class_name WallSegment
extends RefCounted
## A wall as a line segment on the board. Pure data.

var start: Vector2
var end: Vector2
var is_boundary: bool


func _init(p_start: Vector2 = Vector2.ZERO, p_end: Vector2 = Vector2.ZERO, p_boundary: bool = false) -> void:
	start = p_start
	end = p_end
	is_boundary = p_boundary


func get_length() -> float:
	return start.distance_to(end)


func get_direction() -> Vector2:
	return (end - start).normalized()
