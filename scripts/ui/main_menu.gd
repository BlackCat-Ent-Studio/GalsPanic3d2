extends Control
class_name MainMenu
## Main menu: New Game, Continue, Settings buttons.

var _btn_new: Button
var _btn_continue: Button
var _btn_settings: Button
var _title: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_create_background()
	_create_ui()
	_btn_continue.visible = GameManager.save.get_max_unlocked_level() > 0


func _create_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.1, 0.15)
	add_child(bg)


func _create_ui() -> void:
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -150
	center.offset_top = -120
	center.offset_right = 150
	center.offset_bottom = 120
	center.add_theme_constant_override("separation", 20)
	add_child(center)

	_title = Label.new()
	_title.text = "GalsPanic 3D"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 48)
	_title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	center.add_child(_title)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 30
	center.add_child(spacer)

	_btn_new = _make_button("New Game", center)
	_btn_new.pressed.connect(_on_new_game)

	_btn_continue = _make_button("Continue", center)
	_btn_continue.pressed.connect(_on_continue)

	_btn_settings = _make_button("Settings", center)
	_btn_settings.pressed.connect(_on_settings)


func _make_button(text: String, parent: Node) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 50)
	parent.add_child(btn)
	return btn


func _on_new_game() -> void:
	GameManager.save.reset_all()
	GameManager.coins = 0
	GameManager.current_level_index = 0
	SceneManager.change_scene("res://scenes/gameplay.tscn")


func _on_continue() -> void:
	GameManager.current_level_index = GameManager.save.get_current_level()
	GameManager.coins = GameManager.save.get_coins()
	SceneManager.change_scene("res://scenes/gameplay.tscn")


func _on_settings() -> void:
	pass  # Placeholder for settings panel
