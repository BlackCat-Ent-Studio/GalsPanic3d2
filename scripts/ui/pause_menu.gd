extends PanelContainer
class_name PauseMenu
## Pause overlay: Resume, Settings, Main Menu. Works while paused.

var _btn_resume: Button
var _btn_main_menu: Button


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -120
	offset_top = -100
	offset_right = 120
	offset_bottom = 100

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10
	vbox.add_child(spacer)

	_btn_resume = Button.new()
	_btn_resume.text = "Resume"
	_btn_resume.custom_minimum_size.y = 40
	_btn_resume.pressed.connect(_resume)
	vbox.add_child(_btn_resume)

	_btn_main_menu = Button.new()
	_btn_main_menu.text = "Main Menu"
	_btn_main_menu.custom_minimum_size.y = 40
	_btn_main_menu.pressed.connect(_go_to_menu)
	vbox.add_child(_btn_main_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if GameManager.state == GameManager.State.PLAYING:
			_show_pause()
			get_viewport().set_input_as_handled()
		elif GameManager.state == GameManager.State.PAUSED:
			_resume()
			get_viewport().set_input_as_handled()


func _show_pause() -> void:
	visible = true
	GameManager.pause_game()


func _resume() -> void:
	visible = false
	GameManager.resume_game()


func _go_to_menu() -> void:
	visible = false
	GameManager.resume_game()
	SceneManager.change_scene("res://scenes/main_menu.tscn")
