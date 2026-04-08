extends HBoxContainer
class_name GeneratorPicker
## Bottom-center generator selection buttons with stock counts.

var _buttons: Array[Button] = []
var _labels: Array[Label] = []
var _types: Array[int] = [
	GeneratorInventory.TYPE_CROSS4,
	GeneratorInventory.TYPE_UP_DOWN,
	GeneratorInventory.TYPE_LEFT_RIGHT,
]
var _names: Array[String] = ["Cross4", "Up/Down", "Left/Right"]
var _colors: Array[Color] = [
	Color(0.3, 0.8, 1.0),
	Color(0.3, 1.0, 0.5),
	Color(1.0, 0.8, 0.3),
]


func _ready() -> void:
	anchor_left = 0.5
	anchor_top = 1.0
	offset_left = -160
	offset_top = -65
	add_theme_constant_override("separation", 8)

	for i in _types.size():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(100, 50)
		btn.text = _names[i]
		btn.pressed.connect(_on_pressed.bind(i))
		add_child(btn)
		_buttons.append(btn)

		var lbl := Label.new()
		lbl.text = "inf" if _types[i] == GeneratorInventory.TYPE_CROSS4 else "5"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		btn.add_child(lbl)
		lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		lbl.position.y = -16
		_labels.append(lbl)

	GameEvents.inventory_changed.connect(_on_inventory_changed)
	GameEvents.generator_changed.connect(_on_generator_changed)
	# Highlight initial selection
	_update_highlight(GeneratorInventory.TYPE_CROSS4)


func _on_pressed(index: int) -> void:
	GameManager.inventory.select_type(_types[index])


func _on_inventory_changed(type: int, count: int) -> void:
	var idx := _types.find(type)
	if idx < 0:
		return
	_labels[idx].text = "inf" if count < 0 else str(count)
	_buttons[idx].disabled = count == 0


func _on_generator_changed(type: int) -> void:
	_update_highlight(type)


func _update_highlight(active_type: int) -> void:
	for i in _buttons.size():
		var btn := _buttons[i]
		if _types[i] == active_type:
			btn.modulate = _colors[i]
		else:
			btn.modulate = Color(0.6, 0.6, 0.6)
