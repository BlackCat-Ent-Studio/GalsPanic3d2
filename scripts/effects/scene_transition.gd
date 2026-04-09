extends CanvasLayer
class_name SceneTransition
## Black wipe transition between scenes.

var _rect: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)


## Fade to black, call callback, fade back in.
func transition(callback: Callable) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	GameEvents.transition_started.emit()

	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", 1.0, 0.3)
	tween.tween_callback(callback)
	tween.tween_interval(0.2)
	tween.tween_property(_rect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_on_transition_done)


func _on_transition_done() -> void:
	_is_transitioning = false
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameEvents.transition_ended.emit()
