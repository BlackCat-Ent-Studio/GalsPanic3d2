extends Control
class_name LevelSelect
## Grid of level buttons populated dynamically from res://resources/levels/.
## Only levels that exist as .tres files are shown.

const COLS := 5
const LEVELS_DIR := "res://resources/levels/"
const BTN_SIZE := Vector2(70, 50)
const GAP := 8.0

var _buttons: Array[Button] = []
var _back_btn: Button
var _level_indices: Array[int] = []  # Sorted list of available level numbers (1-based)


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


func _scan_levels() -> void:
	_level_indices.clear()
	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		# Match level_XX.tres pattern
		if f.begins_with("level_") and f.ends_with(".tres"):
			var num_str := f.replace("level_", "").replace(".tres", "")
			if num_str.is_valid_int():
				_level_indices.append(int(num_str))
		f = dir.get_next()
	_level_indices.sort()


func _create_grid() -> void:
	_scan_levels()

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", int(GAP))
	grid.add_theme_constant_override("v_separation", int(GAP))
	# Center the grid
	var row_count: int = maxi(1, ceili(float(_level_indices.size()) / float(COLS)))
	var grid_w := COLS * (BTN_SIZE.x + GAP) - GAP
	var grid_h := row_count * (BTN_SIZE.y + GAP) - GAP
	grid.anchor_left = 0.5
	grid.anchor_top = 0.5
	grid.offset_left = -grid_w / 2.0
	grid.offset_top = -grid_h / 2.0 + 20
	add_child(grid)

	# Show "no levels" message if empty
	if _level_indices.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No levels found.\nUse the Level Editor to create one."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		empty_label.anchor_left = 0.5
		empty_label.anchor_top = 0.5
		empty_label.offset_left = -160
		empty_label.offset_top = -20
		empty_label.size = Vector2(320, 60)
		add_child(empty_label)
		return

	var max_unlocked := GameManager.save.get_max_unlocked_level()

	for level_num: int in _level_indices:
		var level_index := level_num - 1  # 0-based for GameManager
		var btn := Button.new()
		btn.text = str(level_num)
		btn.custom_minimum_size = BTN_SIZE
		btn.add_theme_font_size_override("font_size", 16)

		if level_index <= max_unlocked:
			btn.pressed.connect(_on_level_pressed.bind(level_index))
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
