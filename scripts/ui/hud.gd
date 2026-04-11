extends CanvasLayer
class_name HUD
## Root HUD: builds all UI elements programmatically.

var generator_picker: GeneratorPicker
var claim_bar: ClaimProgressBar
var timer_bar: TimerBar
var lives_display: LivesDisplay
var power_up_panel: PowerUpPanel
var center_messages: CenterMessages
var pause_menu: PauseMenu
var tutorial_manager: TutorialManager


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	generator_picker = GeneratorPicker.new()
	root.add_child(generator_picker)

	claim_bar = ClaimProgressBar.new()
	root.add_child(claim_bar)

	timer_bar = TimerBar.new()
	root.add_child(timer_bar)

	lives_display = LivesDisplay.new()
	root.add_child(lives_display)

	power_up_panel = PowerUpPanel.new()
	root.add_child(power_up_panel)

	center_messages = CenterMessages.new()
	root.add_child(center_messages)

	pause_menu = PauseMenu.new()
	root.add_child(pause_menu)

	tutorial_manager = TutorialManager.new()
	add_child(tutorial_manager)
	tutorial_manager.setup(root)

	# Start tutorial on level 1
	if GameManager.current_level_index == 0:
		tutorial_manager.start()
