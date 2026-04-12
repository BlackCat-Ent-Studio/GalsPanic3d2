@tool
extends VBoxContainer
## Level Editor: visual board placement + clearly labeled parameter sections.

const LEVELS_DIR := "res://resources/levels/"
const BoardPreview = preload("res://addons/level_editor/board_preview.gd")

# Toolbar
var _file_dropdown: OptionButton

# Level properties
var _level_num_spin: SpinBox
var _claim_spin: SpinBox
var _time_spin: SpinBox
var _coins_spin: SpinBox

# Enemy defaults
var _speed_spin: SpinBox
var _radius_spin: SpinBox

# Boss behavior
var _summon_interval_spin: SpinBox
var _summon_type_option: OptionButton
var _max_summons_spin: SpinBox

# Ghost invisibility
var _invis_on_spin: SpinBox
var _invis_off_spin: SpinBox

# Board + tools
var _board_preview: Control
var _tool_buttons: Dictionary = {}
var _active_tool: String = "red"
var _status_label: Label


func _init() -> void:
	name = "LevelEditorPanel"
	custom_minimum_size.y = 380
	add_theme_constant_override("separation", 4)
	_build_toolbar()
	_build_main_area()
	_build_status()


# ============================================================================
# TOP TOOLBAR — File operations
# ============================================================================

func _build_toolbar() -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	add_child(bar)
	bar.add_child(_lbl("Level File:"))
	_file_dropdown = OptionButton.new()
	_file_dropdown.custom_minimum_size.x = 180
	bar.add_child(_file_dropdown)
	for d: Array in [["Load", _on_load], ["Save", _on_save], ["+ New", _on_new], ["↻ Refresh", _refresh_file_list]]:
		var b := Button.new()
		b.text = d[0]
		b.pressed.connect(d[1])
		bar.add_child(b)
	add_child(HSeparator.new())
	_refresh_file_list()


# ============================================================================
# MAIN AREA — left: enemies + board, right: properties
# ============================================================================

func _build_main_area() -> void:
	var hsplit := HSplitContainer.new()
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(hsplit)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 320
	hsplit.add_child(left)
	_build_enemy_picker(left)
	_board_preview = BoardPreview.new()
	_board_preview.fireball_placed.connect(_on_fireball_placed)
	_board_preview.fireball_removed.connect(_on_fireball_removed)
	left.add_child(_board_preview)

	var right := ScrollContainer.new()
	right.custom_minimum_size.x = 250
	hsplit.add_child(right)
	var right_box := VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 4)
	right.add_child(right_box)
	_build_level_properties(right_box)
	_build_enemy_defaults(right_box)
	_build_boss_behavior(right_box)
	_build_ghost_invisibility(right_box)


# ============================================================================
# LEFT — Enemy picker toolbar + board
# ============================================================================

func _build_enemy_picker(parent: Control) -> void:
	parent.add_child(_section_label("ENEMIES"))
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	parent.add_child(bar)
	var tools := [
		["Red", "red", Color(1, 0.2, 0.15)],
		["Yellow", "yellow", Color(1, 0.85, 0.1)],
		["White", "white", Color(0.9, 0.9, 1)],
		["Tank Boss", "boss_tank", Color(0.8, 0.1, 0.9)],
		["Ghost Boss", "boss_ghost", Color(0.3, 0.9, 0.7)],
		["Erase", "erase", Color(0.6, 0.6, 0.6)],
	]
	for t: Array in tools:
		var btn := Button.new()
		btn.text = t[0]
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(72, 28)
		btn.modulate = t[2]
		btn.pressed.connect(_on_tool_selected.bind(t[1]))
		bar.add_child(btn)
		_tool_buttons[t[1]] = btn
	_tool_buttons["red"].set_pressed_no_signal(true)


# ============================================================================
# RIGHT — Property sections with clear labels
# ============================================================================

func _build_level_properties(parent: Control) -> void:
	parent.add_child(_section_label("LEVEL PROPERTIES"))
	var grid := _make_grid()
	parent.add_child(grid)
	grid.add_child(_lbl("Level Number"))
	_level_num_spin = _spin(1, 100, 1, 1)
	grid.add_child(_level_num_spin)
	grid.add_child(_lbl("Win Threshold"))
	_claim_spin = _spin(10, 95, 5, 50)
	_claim_spin.suffix = "%"
	grid.add_child(_claim_spin)
	grid.add_child(_lbl("Time Limit"))
	_time_spin = _spin(30, 600, 10, 120)
	_time_spin.suffix = "s"
	grid.add_child(_time_spin)
	grid.add_child(_lbl("Reward / Excess"))
	_coins_spin = _spin(0.5, 10.0, 0.5, 1.0)
	grid.add_child(_coins_spin)


func _build_enemy_defaults(parent: Control) -> void:
	parent.add_child(HSeparator.new())
	parent.add_child(_section_label("ENEMY DEFAULTS"))
	var hint := _lbl("Applied to next placement")
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.add_theme_font_size_override("font_size", 10)
	parent.add_child(hint)
	var grid := _make_grid()
	parent.add_child(grid)
	grid.add_child(_lbl("Move Speed"))
	_speed_spin = _spin(0.5, 15.0, 0.5, 3.0)
	grid.add_child(_speed_spin)
	grid.add_child(_lbl("Hitbox Radius"))
	_radius_spin = _spin(0.1, 1.0, 0.05, 0.25)
	grid.add_child(_radius_spin)


func _build_boss_behavior(parent: Control) -> void:
	parent.add_child(HSeparator.new())
	parent.add_child(_section_label("BOSS — SUMMON BEHAVIOR"))
	var grid := _make_grid()
	parent.add_child(grid)
	grid.add_child(_lbl("Spawn Every"))
	_summon_interval_spin = _spin(2, 30, 1, 8)
	_summon_interval_spin.suffix = "s"
	grid.add_child(_summon_interval_spin)
	grid.add_child(_lbl("Mini Type"))
	_summon_type_option = OptionButton.new()
	_summon_type_option.add_item("Red", 0)
	_summon_type_option.add_item("Yellow", 1)
	_summon_type_option.add_item("White", 2)
	grid.add_child(_summon_type_option)
	grid.add_child(_lbl("Max Active Minis"))
	_max_summons_spin = _spin(1, 10, 1, 3)
	grid.add_child(_max_summons_spin)


func _build_ghost_invisibility(parent: Control) -> void:
	parent.add_child(HSeparator.new())
	parent.add_child(_section_label("GHOST BOSS — INVISIBILITY"))
	var grid := _make_grid()
	parent.add_child(grid)
	grid.add_child(_lbl("Visible Time"))
	_invis_on_spin = _spin(2, 30, 1, 10)
	_invis_on_spin.suffix = "s"
	grid.add_child(_invis_on_spin)
	grid.add_child(_lbl("Hidden Time"))
	_invis_off_spin = _spin(1, 20, 1, 5)
	_invis_off_spin.suffix = "s"
	grid.add_child(_invis_off_spin)


func _build_status() -> void:
	add_child(HSeparator.new())
	_status_label = Label.new()
	_status_label.text = "Ready"
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.55, 0.7, 0.9))
	add_child(_status_label)


# ============================================================================
# Tool selection / placement
# ============================================================================

func _on_tool_selected(tool_name: String) -> void:
	_active_tool = tool_name
	_board_preview.active_tool = tool_name
	for key: String in _tool_buttons:
		_tool_buttons[key].set_pressed_no_signal(key == tool_name)


func _on_fireball_placed(board_pos: Vector2, fb_type: String) -> void:
	var entry: Dictionary = {
		"type": fb_type, "position": board_pos,
		"speed": _speed_spin.value, "radius": _radius_spin.value,
	}
	if fb_type.begins_with("boss"):
		var summon_types := ["red", "yellow", "white"]
		entry["summon_interval"] = _summon_interval_spin.value
		entry["summon_type"] = summon_types[_summon_type_option.selected]
		entry["max_summons"] = int(_max_summons_spin.value)
		entry["invisible_on_time"] = _invis_on_spin.value
		entry["invisible_off_time"] = _invis_off_spin.value
	_board_preview.fireballs.append(entry)
	_board_preview.queue_redraw()
	_status("%d enemies placed" % _board_preview.fireballs.size())


func _on_fireball_removed(index: int) -> void:
	if index >= 0 and index < _board_preview.fireballs.size():
		_board_preview.fireballs.remove_at(index)
		_board_preview.queue_redraw()
		_status("%d enemies placed" % _board_preview.fireballs.size())


# ============================================================================
# File operations
# ============================================================================

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
	_status("Found %d level files" % _file_dropdown.item_count)


func _on_load() -> void:
	if _file_dropdown.item_count == 0:
		_status("No files to load"); return
	var path := LEVELS_DIR + _file_dropdown.get_item_text(_file_dropdown.selected)
	var res: Resource = ResourceLoader.load(path)
	if res == null:
		_status("Failed to load: " + path); return
	_level_num_spin.value = res.level_number
	_claim_spin.value = res.claim_percentage_to_win * 100.0
	_time_spin.value = res.time_limit_seconds
	_coins_spin.value = res.coins_per_excess_cell
	_board_preview.fireballs = res.fireball_placements.duplicate(true)
	_board_preview.queue_redraw()
	_status("Loaded: " + path.get_file())


func _on_save() -> void:
	var cfg := LevelConfig.new()
	cfg.level_number = int(_level_num_spin.value)
	cfg.claim_percentage_to_win = _claim_spin.value / 100.0
	cfg.time_limit_seconds = _time_spin.value
	cfg.coins_per_excess_cell = _coins_spin.value
	cfg.fireball_placements = _board_preview.fireballs.duplicate(true)
	cfg.fireball_spawn_entries = _build_spawn_entries()
	var filename := "level_%02d.tres" % cfg.level_number
	var err := ResourceSaver.save(cfg, LEVELS_DIR + filename)
	if err == OK:
		_status("Saved: " + filename); _refresh_file_list()
	else:
		_status("Save error: %d" % err)


func _on_new() -> void:
	_level_num_spin.value = _file_dropdown.item_count + 1
	_claim_spin.value = 50; _time_spin.value = 120; _coins_spin.value = 1.0
	_board_preview.fireballs.clear()
	_board_preview.queue_redraw()
	_status("New level template")


func _build_spawn_entries() -> Array:
	var counts: Dictionary = {}
	for fb: Dictionary in _board_preview.fireballs:
		var t: String = fb["type"]
		counts[t] = counts.get(t, 0) + 1
	var result: Array = []
	for t: String in counts:
		result.append({"type": t, "count": counts[t], "speed_level": 0})
	return result


# ============================================================================
# Helpers
# ============================================================================

func _lbl(text: String) -> Label:
	var l := Label.new(); l.text = text; return l


func _section_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	return l


func _make_grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 4)
	return g


func _spin(mn: float, mx: float, st: float, val: float) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = mn; s.max_value = mx; s.step = st; s.value = val
	s.custom_minimum_size.x = 90
	return s


func _status(msg: String) -> void:
	if _status_label: _status_label.text = msg
