extends HBoxContainer
class_name GeneratorPicker
## Bottom-center compact generator buttons with stock counts.

var _buttons: Array[Button] = []
var _types: Array[int] = [
	GeneratorInventory.TYPE_CROSS4,
	GeneratorInventory.TYPE_UP_DOWN,
	GeneratorInventory.TYPE_LEFT_RIGHT,
]
var _names: Array[String] = ["Cross4", "Up/Down", "L/R"]
var _colors: Array[Color] = [
	Color(0.3, 0.8, 1.0),
	Color(0.3, 1.0, 0.5),
	Color(1.0, 0.8, 0.3),
]


func _ready() -> void:
	anchor_left = 0.5
	anchor_top = 1.0
	offset_left = -135
	offset_top = -42
	add_theme_constant_override("separation", 6)

	for i in _types.size():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(85, 32)
		var stock := "inf" if _types[i] == GeneratorInventory.TYPE_CROSS4 else "5"
		btn.text = "%s [%s]" % [_names[i], stock]
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_pressed.bind(i))
		add_child(btn)
		_buttons.append(btn)

	GameEvents.inventory_changed.connect(_on_inventory_changed)
	GameEvents.generator_changed.connect(_on_generator_changed)
	_update_highlight(GeneratorInventory.TYPE_CROSS4)


func _on_pressed(index: int) -> void:
	GameManager.inventory.select_type(_types[index])


func _on_inventory_changed(type: int, count: int) -> void:
	var idx := _types.find(type)
	if idx < 0:
		return
	var stock := "inf" if count < 0 else str(count)
	_buttons[idx].text = "%s [%s]" % [_names[idx], stock]
	_buttons[idx].disabled = count == 0


func _on_generator_changed(type: int) -> void:
	_update_highlight(type)


func _update_highlight(active_type: int) -> void:
	for i in _buttons.size():
		if _types[i] == active_type:
			_buttons[i].modulate = _colors[i]
		else:
			_buttons[i].modulate = Color(0.6, 0.6, 0.6)
