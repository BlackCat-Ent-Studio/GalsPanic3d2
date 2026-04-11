extends VBoxContainer
class_name PowerUpPanel
## Compact top-right: coin count + power-up toggle buttons.

var _coin_label: Label
var _btn_iron: Button
var _btn_speed: Button


func _ready() -> void:
	anchor_left = 1.0
	anchor_top = 0.0
	offset_left = -130
	offset_top = 6
	add_theme_constant_override("separation", 4)

	_coin_label = Label.new()
	_coin_label.text = "Coins: 0"
	_coin_label.add_theme_font_size_override("font_size", 12)
	_coin_label.add_theme_color_override("font_color", Color.GOLD)
	add_child(_coin_label)

	_btn_iron = Button.new()
	_btn_iron.text = "Iron (50)"
	_btn_iron.toggle_mode = true
	_btn_iron.custom_minimum_size = Vector2(120, 28)
	_btn_iron.pressed.connect(_on_iron_pressed)
	add_child(_btn_iron)

	_btn_speed = Button.new()
	_btn_speed.text = "Speed (15)"
	_btn_speed.toggle_mode = true
	_btn_speed.custom_minimum_size = Vector2(120, 28)
	_btn_speed.pressed.connect(_on_speed_pressed)
	add_child(_btn_speed)

	GameEvents.coins_changed.connect(_update_coins)
	GameEvents.power_up_changed.connect(_update_buttons)
	GameEvents.power_up_build_state_changed.connect(_on_build_state)
	_update_coins(GameManager.coins)


func _on_iron_pressed() -> void:
	GameManager.power_up_manager.toggle_power_up(PowerUpManager.PowerUp.IRON_GENERATOR)

func _on_speed_pressed() -> void:
	GameManager.power_up_manager.toggle_power_up(PowerUpManager.PowerUp.SPEED_WALL)

func _update_coins(amount: int) -> void:
	_coin_label.text = "Coins: %d" % amount
	_btn_iron.disabled = amount < 50
	_btn_speed.disabled = amount < 15

func _update_buttons(active: int) -> void:
	_btn_iron.set_pressed_no_signal(active == PowerUpManager.PowerUp.IRON_GENERATOR)
	_btn_speed.set_pressed_no_signal(active == PowerUpManager.PowerUp.SPEED_WALL)

func _on_build_state(locked: bool) -> void:
	_btn_iron.disabled = locked or GameManager.coins < 50
	_btn_speed.disabled = locked or GameManager.coins < 15
