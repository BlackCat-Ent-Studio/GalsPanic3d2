@tool
extends HBoxContainer
## Single fireball entry row: type dropdown, count, speed, radius, delete button.

signal entry_changed()
signal entry_deleted(entry: HBoxContainer)

var type_option: OptionButton
var count_spin: SpinBox
var speed_spin: SpinBox
var radius_spin: SpinBox


func _init() -> void:
	add_theme_constant_override("separation", 6)

	# Type dropdown
	var type_label := Label.new()
	type_label.text = "Type:"
	add_child(type_label)
	type_option = OptionButton.new()
	type_option.add_item("Red (Straight)", 0)
	type_option.add_item("Yellow (Curve)", 1)
	type_option.add_item("White (Zigzag)", 2)
	type_option.item_selected.connect(func(_i: int) -> void: entry_changed.emit())
	add_child(type_option)

	# Count
	var count_label := Label.new()
	count_label.text = "x"
	add_child(count_label)
	count_spin = SpinBox.new()
	count_spin.min_value = 1
	count_spin.max_value = 20
	count_spin.value = 1
	count_spin.custom_minimum_size.x = 60
	count_spin.value_changed.connect(func(_v: float) -> void: entry_changed.emit())
	add_child(count_spin)

	# Speed
	var speed_label := Label.new()
	speed_label.text = "Spd:"
	add_child(speed_label)
	speed_spin = SpinBox.new()
	speed_spin.min_value = 0.5
	speed_spin.max_value = 15.0
	speed_spin.step = 0.5
	speed_spin.value = 3.0
	speed_spin.custom_minimum_size.x = 70
	speed_spin.value_changed.connect(func(_v: float) -> void: entry_changed.emit())
	add_child(speed_spin)

	# Radius
	var rad_label := Label.new()
	rad_label.text = "Rad:"
	add_child(rad_label)
	radius_spin = SpinBox.new()
	radius_spin.min_value = 0.1
	radius_spin.max_value = 1.0
	radius_spin.step = 0.05
	radius_spin.value = 0.25
	radius_spin.custom_minimum_size.x = 70
	radius_spin.value_changed.connect(func(_v: float) -> void: entry_changed.emit())
	add_child(radius_spin)

	# Delete button
	var del_btn := Button.new()
	del_btn.text = "X"
	del_btn.custom_minimum_size = Vector2(30, 0)
	del_btn.pressed.connect(func() -> void: entry_deleted.emit(self))
	add_child(del_btn)


func get_data() -> Dictionary:
	var type_names := ["red", "yellow", "white"]
	return {
		"type": type_names[type_option.selected],
		"count": int(count_spin.value),
		"speed_level": 0,
		"base_speed": speed_spin.value,
		"radius": radius_spin.value,
	}


func set_data(data: Dictionary) -> void:
	var type_map := {"red": 0, "yellow": 1, "white": 2}
	type_option.selected = type_map.get(data.get("type", "red"), 0)
	count_spin.value = data.get("count", 1)
	speed_spin.value = data.get("base_speed", 3.0)
	radius_spin.value = data.get("radius", 0.25)
