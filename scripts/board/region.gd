class_name Region
extends RefCounted
## A polygonal region on the board. Vertices in CCW winding order.

var polygon: PackedVector2Array
var is_claimed: bool = false
var _cached_area: float = -1.0


func _init(p_polygon: PackedVector2Array = PackedVector2Array(), p_claimed: bool = false) -> void:
	polygon = p_polygon
	is_claimed = p_claimed
	_cached_area = -1.0


func get_area() -> float:
	if _cached_area < 0.0:
		_cached_area = GeometryUtils.polygon_area(polygon)
	return _cached_area


func contains_point(point: Vector2) -> bool:
	return GeometryUtils.point_in_polygon(point, polygon)


func invalidate_cache() -> void:
	_cached_area = -1.0


## Ensure polygon is CCW. Flip if needed.
func ensure_ccw() -> void:
	if GeometryUtils.signed_polygon_area(polygon) < 0.0:
		polygon.reverse()
		invalidate_cache()
