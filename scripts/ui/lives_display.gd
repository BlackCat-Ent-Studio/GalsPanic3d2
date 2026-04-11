extends HBoxContainer
class_name LivesDisplay
## Compact life icons top-left. Small circles instead of big squares.

const MAX_LIVES := 5
const ICON_SIZE := 16.0

var _icons: Array[ColorRect] = []


func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	offset_left = 10
	offset_top = 8
	add_theme_constant_override("separation", 4)

	for i in MAX_LIVES:
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.color = Color(1.0, 0.3, 0.35)
		add_child(icon)
		_icons.append(icon)

	GameEvents.lives_changed.connect(_update)


func _update(lives: int) -> void:
	for i in _icons.size():
		if i < lives:
			_icons[i].modulate.a = 1.0
		elif _icons[i].modulate.a > 0.0:
			var tween := create_tween()
			tween.tween_property(_icons[i], "modulate:a", 0.0, 0.5)
