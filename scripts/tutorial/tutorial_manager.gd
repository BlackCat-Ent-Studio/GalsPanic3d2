extends Node
class_name TutorialManager
## Simplified tutorial: shows instruction text for 6 steps on level 1.

var _steps: Array[Dictionary] = []
var _current_step: int = -1
var _is_active: bool = false
var _label: Label
var _skip_btn: Button

# Condition tracking
var _drag_happened: bool = false
var _cancel_happened: bool = false
var _wall_placed: bool = false
var _arm_destroyed_seen: bool = false
var _wall_completed_count: int = 0


func setup(ui_root: Control) -> void:
	_create_ui(ui_root)
	_define_steps()
	_connect_signals()


func start() -> void:
	_is_active = true
	_current_step = -1
	_advance()


func is_active() -> bool:
	return _is_active


func _create_ui(root: Control) -> void:
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_label.offset_top = -130
	_label.offset_left = -250
	_label.offset_right = 250
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.visible = false
	root.add_child(_label)

	_skip_btn = Button.new()
	_skip_btn.text = "Skip Tutorial"
	_skip_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_skip_btn.offset_top = -100
	_skip_btn.offset_left = -60
	_skip_btn.offset_right = 60
	_skip_btn.pressed.connect(_complete)
	_skip_btn.visible = false
	root.add_child(_skip_btn)


func _define_steps() -> void:
	_steps = [
		{"text": "Drag on the board to preview wall placement", "check": "_check_drag"},
		{"text": "Release outside the board to cancel", "check": "_check_cancel"},
		{"text": "Place a wall in a safe area away from fireballs", "check": "_check_wall_placed"},
		{"text": "Place near a fireball to see what happens...", "check": "_check_arm_destroyed"},
		{"text": "Keep claiming territory!", "check": "_check_two_walls"},
		{"text": "Claim enough territory to win the level!", "check": "_check_never"},
	]


func _connect_signals() -> void:
	GameEvents.drag_started.connect(func() -> void: _drag_happened = true)
	GameEvents.wall_placement_cancelled.connect(func() -> void: _cancel_happened = true)
	GameEvents.wall_placement_started.connect(func() -> void:
		_wall_placed = true
		_wall_completed_count += 1
	)
	GameEvents.arm_destroyed.connect(func() -> void: _arm_destroyed_seen = true)
	GameEvents.level_complete.connect(func(_idx: int) -> void: _complete())


func _advance() -> void:
	_current_step += 1
	if _current_step >= _steps.size():
		_complete()
		return
	var step: Dictionary = _steps[_current_step]
	_label.text = step["text"]
	_label.visible = true
	_skip_btn.visible = true
	# Reset condition flags for new step
	_drag_happened = false
	_cancel_happened = false
	_wall_placed = false
	_arm_destroyed_seen = false


func _process(_delta: float) -> void:
	if not _is_active or _current_step < 0:
		return
	var step: Dictionary = _steps[_current_step]
	var method: String = step["check"]
	if call(method):
		_advance()


func notify_drag() -> void:
	_drag_happened = true

func notify_cancel() -> void:
	_cancel_happened = true

func _check_drag() -> bool:
	return _drag_happened

func _check_cancel() -> bool:
	return _cancel_happened

func _check_wall_placed() -> bool:
	return _wall_placed and not _arm_destroyed_seen

func _check_arm_destroyed() -> bool:
	return _arm_destroyed_seen

func _check_two_walls() -> bool:
	return _wall_completed_count >= 3

func _check_never() -> bool:
	return false  # Completed via level_complete signal


func _complete() -> void:
	_is_active = false
	_label.visible = false
	_skip_btn.visible = false
	GameEvents.tutorial_completed.emit()
	set_process(false)
