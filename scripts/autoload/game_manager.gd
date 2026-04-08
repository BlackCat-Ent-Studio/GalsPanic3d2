extends Node
## Game state machine: manages lives, timer, scoring, level progression.

enum State { MENU, PLAYING, PAUSED, LEVEL_COMPLETE, GAME_OVER }

const INITIAL_LIVES := 5
const FIREBALL_CONFIGS := {
	"red": "res://resources/fireball_red.tres",
	"yellow": "res://resources/fireball_yellow.tres",
	"white": "res://resources/fireball_white.tres",
}

var state: int = State.MENU
var current_level_index: int = 0
var current_level_config: LevelConfig
var lives: int = INITIAL_LIVES
var timer_remaining: float = 0.0
var coins: int = 0
var save: SaveData = SaveData.new()
var inventory: GeneratorInventory = GeneratorInventory.new()
var power_up_manager: PowerUpManager = PowerUpManager.new()


func _ready() -> void:
	save.load_data()
	coins = save.get_coins()
	current_level_index = save.get_current_level()
	GameEvents.life_lost.connect(_on_life_lost)
	GameEvents.claim_percentage_changed.connect(_on_claim_percentage_changed)


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return
	timer_remaining -= delta
	GameEvents.timer_changed.emit(timer_remaining, current_level_config.time_limit_seconds)
	if timer_remaining <= 0.0:
		timer_remaining = 0.0
		_game_over()


func start_level(level_index: int) -> void:
	current_level_index = level_index
	current_level_config = LevelGenerator.generate(level_index)
	lives = INITIAL_LIVES
	timer_remaining = current_level_config.time_limit_seconds
	state = State.PLAYING
	GameEvents.lives_changed.emit(lives)


## Convert fireball spawn entries to format FireballManager expects.
func get_spawn_entries_for_manager() -> Array:
	var entries: Array = []
	for entry: Dictionary in current_level_config.fireball_spawn_entries:
		var type_key: String = entry["type"]
		if FIREBALL_CONFIGS.has(type_key):
			var cfg: Resource = load(FIREBALL_CONFIGS[type_key])
			entries.append({"config": cfg, "count": entry["count"]})
	return entries


func _on_life_lost() -> void:
	lives -= 1
	GameEvents.lives_changed.emit(lives)
	if lives <= 0:
		_game_over()


func _on_claim_percentage_changed(pct: float) -> void:
	if state != State.PLAYING:
		return
	if current_level_config and pct >= current_level_config.claim_percentage_to_win:
		_level_complete()


func _level_complete() -> void:
	state = State.LEVEL_COMPLETE
	# Calculate coin reward from excess area
	var pct: float = GameEvents.claim_percentage_changed.get_connections().size()  # placeholder
	var excess := maxf(0.0, 0.0)  # Will be calculated from actual percentage
	# For now, award flat coins
	var earned := 10
	coins += earned
	save.set_coins(coins)
	var next := current_level_index + 1
	save.set_current_level(next)
	save.set_max_unlocked_level(maxi(next, save.get_max_unlocked_level()))
	GameEvents.coins_changed.emit(coins)
	GameEvents.level_complete.emit(current_level_index)


func _game_over() -> void:
	state = State.GAME_OVER
	GameEvents.game_over.emit()


func pause_game() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		get_tree().paused = true
		GameEvents.game_paused.emit()


func resume_game() -> void:
	if state == State.PAUSED:
		state = State.PLAYING
		get_tree().paused = false
		GameEvents.game_resumed.emit()


func restart_level() -> void:
	state = State.MENU
	get_tree().paused = false
	start_level(current_level_index)
