class_name GeneratorInventory
extends RefCounted
## Tracks limited stock for UpDown/LeftRight generators. Cross4 is unlimited.

# Type constants matching GeneratorConfig.Type enum
const TYPE_CROSS4 := 0
const TYPE_UP_DOWN := 1
const TYPE_LEFT_RIGHT := 2

var _stock: Dictionary = {
	TYPE_CROSS4: -1,     # -1 = unlimited
	TYPE_UP_DOWN: 5,
	TYPE_LEFT_RIGHT: 5,
}
var selected_type: int = TYPE_CROSS4


func get_stock(type: int) -> int:
	return _stock.get(type, 0)


func is_available(type: int) -> bool:
	var stock: int = _stock.get(type, 0)
	return stock == -1 or stock > 0


func consume(type: int) -> bool:
	if not is_available(type):
		return false
	if _stock[type] > 0:
		_stock[type] -= 1
	GameEvents.inventory_changed.emit(type, _stock[type])
	return true


func add_stock(type: int, amount: int = 1) -> void:
	if _stock.get(type, 0) == -1:
		return  # unlimited, ignore
	_stock[type] = _stock.get(type, 0) + amount
	GameEvents.inventory_changed.emit(type, _stock[type])


func select_type(type: int) -> void:
	if not is_available(type):
		type = TYPE_CROSS4
	selected_type = type
	GameEvents.generator_changed.emit(type)


func get_config_for_selected() -> Resource:
	match selected_type:
		TYPE_UP_DOWN:
			return preload("res://resources/generator_up_down.tres")
		TYPE_LEFT_RIGHT:
			return preload("res://resources/generator_left_right.tres")
		_:
			return preload("res://resources/generator_cross4.tres")
