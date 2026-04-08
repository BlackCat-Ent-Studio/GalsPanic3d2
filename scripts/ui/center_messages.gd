extends Control
class_name CenterMessages
## Center-screen messages for Level Complete and Game Over.

var _label: Label


func _ready() -> void:
	anchor_left = 0.5
	anchor_top = 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 36)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.position = Vector2(-200, -50)
	_label.size = Vector2(400, 100)
	add_child(_label)

	GameEvents.level_complete.connect(_show_level_complete)
	GameEvents.game_over.connect(_show_game_over)


func _show_level_complete(level_index: int) -> void:
	_label.text = "Level %d Complete!" % (level_index + 1)
	_animate_in()


func _show_game_over() -> void:
	_label.text = "Game Over"
	_label.add_theme_color_override("font_color", Color.RED)
	_animate_in()


func _animate_in() -> void:
	visible = true
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
