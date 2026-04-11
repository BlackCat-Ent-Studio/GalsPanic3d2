extends Control
class_name CenterMessages
## Center-screen messages: auto-advance on win, retry/menu buttons on lose.

var _label: Label
var _btn_retry: Button
var _btn_menu: Button
var _btn_container: HBoxContainer


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
	_label.position = Vector2(-200, -60)
	_label.size = Vector2(400, 80)
	add_child(_label)

	# Buttons for game over (hidden by default)
	_btn_container = HBoxContainer.new()
	_btn_container.position = Vector2(-130, 30)
	_btn_container.add_theme_constant_override("separation", 20)
	_btn_container.visible = false
	add_child(_btn_container)

	_btn_retry = Button.new()
	_btn_retry.text = "Retry"
	_btn_retry.custom_minimum_size = Vector2(120, 45)
	_btn_retry.pressed.connect(_on_retry)
	_btn_container.add_child(_btn_retry)

	_btn_menu = Button.new()
	_btn_menu.text = "Main Menu"
	_btn_menu.custom_minimum_size = Vector2(120, 45)
	_btn_menu.pressed.connect(_on_menu)
	_btn_container.add_child(_btn_menu)

	GameEvents.level_complete.connect(_show_level_complete)
	GameEvents.game_over.connect(_show_game_over)


func _show_level_complete(level_index: int) -> void:
	_label.add_theme_color_override("font_color", Color.GOLD)
	_label.text = "Level %d Complete!" % (level_index + 1)
	_btn_container.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_animate_in()
	# Auto-advance to next level after 2 seconds
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(_advance_to_next_level)


func _show_game_over() -> void:
	_label.add_theme_color_override("font_color", Color.RED)
	_label.text = "Game Over"
	_btn_container.visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_animate_in()
	# Show buttons after message animates in
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(func() -> void: _btn_container.visible = true)


func _animate_in() -> void:
	visible = true
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func _advance_to_next_level() -> void:
	visible = false
	GameManager.current_level_index += 1
	GameManager.save.set_current_level(GameManager.current_level_index)
	SceneManager.change_scene("res://scenes/gameplay.tscn")


func _on_retry() -> void:
	visible = false
	SceneManager.change_scene("res://scenes/gameplay.tscn")


func _on_menu() -> void:
	visible = false
	SceneManager.change_scene("res://scenes/main_menu.tscn")
