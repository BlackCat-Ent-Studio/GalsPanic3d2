class_name PowerUpManager
extends RefCounted
## Manages power-up activation, coin spending, and build integration.

enum PowerUp { NONE, IRON_GENERATOR, SPEED_WALL }

const COSTS := {
	PowerUp.IRON_GENERATOR: 50,
	PowerUp.SPEED_WALL: 15,
}

var active_power_up: int = PowerUp.NONE
var _build_in_progress: bool = false


func toggle_power_up(power_up: int) -> bool:
	if _build_in_progress:
		return false
	if active_power_up == power_up:
		active_power_up = PowerUp.NONE
		GameEvents.power_up_changed.emit(PowerUp.NONE)
		return true
	var cost: int = COSTS.get(power_up, 0)
	if GameManager.coins < cost:
		return false
	active_power_up = power_up
	GameManager.coins -= cost
	GameManager.save.set_coins(GameManager.coins)
	GameEvents.coins_changed.emit(GameManager.coins)
	GameEvents.power_up_changed.emit(power_up)
	return true


func on_build_started() -> void:
	_build_in_progress = true
	GameEvents.power_up_build_state_changed.emit(true)


func on_build_finished() -> void:
	_build_in_progress = false
	active_power_up = PowerUp.NONE
	GameEvents.power_up_changed.emit(PowerUp.NONE)
	GameEvents.power_up_build_state_changed.emit(false)


func is_iron_active() -> bool:
	return active_power_up == PowerUp.IRON_GENERATOR


func get_speed_multiplier() -> float:
	return 2.0 if active_power_up == PowerUp.SPEED_WALL else 1.0
