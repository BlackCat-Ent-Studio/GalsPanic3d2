@tool
extends VBoxContainer
## Level Editor panel with visual board + settings. Click board to place fireballs.

const LEVELS_DIR := "res://resources/levels/"
const BoardPreview = preload("res://addons/level_editor/board_preview.gd")

var _file_dropdown: OptionButton
var _claim_spin: SpinBox
var _time_spin: SpinBox
var _coins_spin: SpinBox
var _level_num_spin: SpinBox
var _board_preview: Control  # BoardPreview
var _status_label: Label
var _tool_buttons: Dictionary = {}  # tool_name → Button
var _active_tool: String = "red"
var _speed_spin: SpinBox
var _radius_spin: SpinBox


func _init() -> void:
	name = "LevelEditorPanel"
	custom_minimum_size.y = 340
	_build_toolbar()
	_build_main_area()
	_build_status()


func _build_toolbar() -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	add_child(bar)
	bar.add_child(_lbl("Level:"))
	_file_dropdown = OptionButton.new()
	_file_dropdown.custom_minimum_size.x = 150
	_file_dropdown.item_selected.connect(_on_file_selected)
	bar.add_child(_file_dropdown)
	for d: Array in [["Load", _on_load], ["Save", _on_save], ["New", _on_new], ["Refresh", _refresh_file_list]]:
		var b := Button.new()
		b.text = d[0]
		b.pressed.connect(d[1])
		bar.add_child(b)
	_refresh_file_list()


func _build_main_area() -> void:
	var hsplit := HSplitContainer.new()
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(hsplit)
	# Left: board preview + tool buttons
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 300
	hsplit.add_child(left)
	_build_tool_bar(left)
	_board_preview = BoardPreview.new()
	_board_preview.fireball_placed.connect(_on_fireball_placed)
	_board_preview.fireball_removed.connect(_on_fireball_removed)
	left.add_child(_board_preview)
	# Right: settings
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 220
	hsplit.add_child(right)
	_build_settings(right)


func _build_tool_bar(parent: Control) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	parent.add_child(bar)
	var tools := [
		["Red", "red", Color(1, 0.2, 0.15)],
		["Yellow", "yellow", Color(1, 0.85, 0.1)],
		["White", "white", Color(0.9, 0.9, 1)],
		["Boss1", "boss_tank", Color(0.8, 0.1, 0.9)],
		["Boss2", "boss_ghost", Color(0.3, 0.9, 0.7)],
		["Erase", "erase", Color(0.6, 0.6, 0.6)],
	]
	for t: Array in tools:
		var btn := Button.new()
		btn.text = t[0]
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(60, 26)
		btn.modulate = t[2]
		btn.pressed.connect(_on_tool_selected.bind(t[1]))
		bar.add_child(btn)
		_tool_buttons[t[1]] = btn
	_tool_buttons["red"].set_pressed_no_signal(true)
	# Speed/radius for new placements
	bar.add_child(_lbl("Spd:"))
	_speed_spin = SpinBox.new()
	_speed_spin.min_value = 0.5
	_speed_spin.max_value = 15.0
	_speed_spin.step = 0.5
	_speed_spin.value = 3.0
	_speed_spin.custom_minimum_size.x = 60
	bar.add_child(_speed_spin)
	bar.add_child(_lbl("Rad:"))
	_radius_spin = SpinBox.new()
	_radius_spin.min_value = 0.1
	_radius_spin.max_value = 1.0
	_radius_spin.step = 0.05
	_radius_spin.value = 0.25
	_radius_spin.custom_minimum_size.x = 60
	bar.add_child(_radius_spin)


func _build_settings(parent: Control) -> void:
	parent.add_child(_lbl("— Level Settings —"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	parent.add_child(grid)

	grid.add_child(_lbl("Level #:"))
	_level_num_spin = _spin(1, 100, 1, 1)
	grid.add_child(_level_num_spin)
	grid.add_child(_lbl("Claim %:"))
	_claim_spin = _spin(10, 95, 5, 50)
	_claim_spin.suffix = "%"
	grid.add_child(_claim_spin)
	grid.add_child(_lbl("Time (s):"))
	_time_spin = _spin(30, 600, 10, 120)
	grid.add_child(_time_spin)
	grid.add_child(_lbl("Coins/excess:"))
	_coins_spin = _spin(0.5, 10.0, 0.5, 1.0)
	grid.add_child(_coins_spin)

	# Fireball count display
	parent.add_child(HSeparator.new())
	parent.add_child(_lbl("Click board to place fireballs"))
	parent.add_child(_lbl("Select type above, then click"))


func _build_status() -> void:
	_status_label = Label.new()
	_status_label.text = "Ready"
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	add_child(_status_label)


func _on_tool_selected(tool_name: String) -> void:
	_active_tool = tool_name
	_board_preview.active_tool = tool_name
	for key: String in _tool_buttons:
		_tool_buttons[key].set_pressed_no_signal(key == tool_name)


func _on_fireball_placed(board_pos: Vector2, fb_type: String) -> void:
	_board_preview.fireballs.append({
		"type": fb_type, "position": board_pos,
		"speed": _speed_spin.value, "radius": _radius_spin.value,
	})
	_board_preview.queue_redraw()
	_status("%d fireballs placed" % _board_preview.fireballs.size())


func _on_fireball_removed(index: int) -> void:
	if index >= 0 and index < _board_preview.fireballs.size():
		_board_preview.fireballs.remove_at(index)
		_board_preview.queue_redraw()
		_status("%d fireballs placed" % _board_preview.fireballs.size())


func _on_file_selected(_idx: int) -> void:
	pass

func _refresh_file_list() -> void:
	_file_dropdown.clear()
	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		DirAccess.make_dir_recursive_absolute(LEVELS_DIR)
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".tres"):
			_file_dropdown.add_item(f)
		f = dir.get_next()
	_status("Found %d levels" % _file_dropdown.item_count)


func _on_load() -> void:
	if _file_dropdown.item_count == 0:
		_status("No files"); return
	var path := LEVELS_DIR + _file_dropdown.get_item_text(_file_dropdown.selected)
	var res: Resource = ResourceLoader.load(path)
	if res == null:
		_status("Failed: " + path); return
	_level_num_spin.value = res.level_number
	_claim_spin.value = res.claim_percentage_to_win * 100.0
	_time_spin.value = res.time_limit_seconds
	_coins_spin.value = res.coins_per_excess_cell
	_board_preview.fireballs = res.fireball_placements.duplicate(true)
	_board_preview.queue_redraw()
	_status("Loaded: " + path)


func _on_save() -> void:
	var cfg := LevelConfig.new()
	cfg.level_number = int(_level_num_spin.value)
	cfg.claim_percentage_to_win = _claim_spin.value / 100.0
	cfg.time_limit_seconds = _time_spin.value
	cfg.coins_per_excess_cell = _coins_spin.value
	cfg.fireball_placements = _board_preview.fireballs.duplicate(true)
	# Also populate legacy spawn_entries for compatibility
	cfg.fireball_spawn_entries = _build_spawn_entries()
	var filename := "level_%02d.tres" % cfg.level_number
	var err := ResourceSaver.save(cfg, LEVELS_DIR + filename)
	if err == OK:
		_status("Saved: " + filename); _refresh_file_list()
	else:
		_status("Error: %d" % err)


func _on_new() -> void:
	_level_num_spin.value = _file_dropdown.item_count + 1
	_claim_spin.value = 50; _time_spin.value = 120; _coins_spin.value = 1.0
	_board_preview.fireballs.clear()
	_board_preview.queue_redraw()
	_status("New level")


func _build_spawn_entries() -> Array:
	var counts: Dictionary = {}
	for fb: Dictionary in _board_preview.fireballs:
		var t: String = fb["type"]
		counts[t] = counts.get(t, 0) + 1
	var result: Array = []
	for t: String in counts:
		result.append({"type": t, "count": counts[t], "speed_level": 0})
	return result


func _lbl(text: String) -> Label:
	var l := Label.new(); l.text = text; return l

func _spin(mn: float, mx: float, st: float, val: float) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = mn; s.max_value = mx; s.step = st; s.value = val
	s.custom_minimum_size.x = 80; return s

func _status(msg: String) -> void:
	if _status_label: _status_label.text = msg
