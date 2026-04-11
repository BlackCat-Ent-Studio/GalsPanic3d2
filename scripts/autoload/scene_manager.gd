extends Node
## Scene transitions with black wipe effect.

var _transition_layer: CanvasLayer
var _rect: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 100
	add_child(_transition_layer)
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.modulate.a = 0.0
	_transition_layer.add_child(_rect)


func change_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	GameEvents.transition_started.emit()
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", 1.0, 0.3)
	tween.tween_callback(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file(scene_path)
	)
	tween.tween_interval(0.1)
	tween.tween_property(_rect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void:
		_is_transitioning = false
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		GameEvents.transition_ended.emit()
	)
