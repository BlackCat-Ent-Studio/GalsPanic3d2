class_name SaveData
extends RefCounted
## Persistent save data via ConfigFile. Stores level progress and coins.

const SAVE_PATH := "user://save_data.cfg"
var _config := ConfigFile.new()


func load_data() -> void:
	_config.load(SAVE_PATH)


func save_data() -> void:
	_config.save(SAVE_PATH)


func get_current_level() -> int:
	return _config.get_value("progress", "current_level", 0)


func set_current_level(level: int) -> void:
	_config.set_value("progress", "current_level", level)
	save_data()


func get_max_unlocked_level() -> int:
	return _config.get_value("progress", "max_unlocked", 0)


func set_max_unlocked_level(level: int) -> void:
	_config.set_value("progress", "max_unlocked", level)
	save_data()


func get_coins() -> int:
	return _config.get_value("economy", "coins", 0)


func set_coins(coins: int) -> void:
	_config.set_value("economy", "coins", coins)
	save_data()


func reset_all() -> void:
	_config = ConfigFile.new()
	save_data()
