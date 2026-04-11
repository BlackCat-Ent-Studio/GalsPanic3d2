extends Control
class_name LevelSelect
## Grid of level buttons. Unlocked = clickable, locked = grayed out.

const COLS := 5
const TOTAL_LEVELS := 30
const BTN_SIZE := Vector2(70, 50)
const GAP := 8.0

var _buttons: Array[Button] = []
var _back_btn: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_create_background()
	_create_title()
	_create_grid()
	_create_back_button()


func _create_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.1, 0.15)
	add_child(bg)


func _create_title() -> void:
	var title := Label.new()
	title.text = "Select Level"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	title.anchor_left = 0.5
	title.anchor_top = 0.0
	title.offset_left = -150
	title.offset_top = 20
	title.size = Vector2(300, 40)
	add_child(title)


func _create_grid() -> void:
	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", int(GAP))
	grid.add_theme_constant_override("v_separation", int(GAP))
	# Center the grid
	var grid_w := COLS * (BTN_SIZE.x + GAP) - GAP
	var grid_h := (TOTAL_LEVELS / COLS) * (BTN_SIZE.y + GAP) - GAP
	grid.anchor_left = 0.5
	grid.anchor_top = 0.5
	grid.offset_left = -grid_w / 2.0
	grid.offset_top = -grid_h / 2.0 + 20
	add_child(grid)

	var max_unlocked := GameManager.save.get_max_unlocked_level()

	for i in TOTAL_LEVELS:
		var btn := Button.new()
		btn.text = str(i + 1)
		btn.custom_minimum_size = BTN_SIZE
		btn.add_theme_font_size_override("font_size", 16)

		if i <= max_unlocked:
			btn.pressed.connect(_on_level_pressed.bind(i))
			btn.modulate = Color.WHITE
		else:
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4)

		grid.add_child(btn)
		_buttons.append(btn)


func _create_back_button() -> void:
	_back_btn = Button.new()
	_back_btn.text = "Back"
	_back_btn.custom_minimum_size = Vector2(100, 40)
	_back_btn.anchor_left = 0.5
	_back_btn.anchor_top = 1.0
	_back_btn.offset_left = -50
	_back_btn.offset_top = -60
	_back_btn.pressed.connect(_on_back)
	add_child(_back_btn)


func _on_level_pressed(level_index: int) -> void:
	GameManager.current_level_index = level_index
	SceneManager.change_scene("res://scenes/gameplay.tscn")


func _on_back() -> void:
	SceneManager.change_scene("res://scenes/main_menu.tscn")
