extends Control
class_name ClaimProgressBar
## Top-center progress bar: thin, compact, doesn't overlap game view.

const BAR_WIDTH := 200.0
const BAR_HEIGHT := 14.0

var _fill: ColorRect
var _bg: ColorRect
var _goal_marker: ColorRect
var _label: Label
var _goal: float = 0.5


func _ready() -> void:
	anchor_left = 0.5
	anchor_top = 0.0
	offset_left = -BAR_WIDTH / 2.0
	offset_top = 6
	size = Vector2(BAR_WIDTH, BAR_HEIGHT + 14)

	_bg = ColorRect.new()
	_bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bg.color = Color(0.1, 0.1, 0.15, 0.8)
	add_child(_bg)

	_fill = ColorRect.new()
	_fill.size = Vector2(0, BAR_HEIGHT)
	_fill.color = Color(0.2, 0.6, 1.0)
	add_child(_fill)

	_goal_marker = ColorRect.new()
	_goal_marker.size = Vector2(2, BAR_HEIGHT + 4)
	_goal_marker.position.y = -2
	_goal_marker.color = Color.WHITE
	add_child(_goal_marker)

	_label = Label.new()
	_label.position = Vector2(BAR_WIDTH + 6, -1)
	_label.add_theme_font_size_override("font_size", 11)
	_label.text = "0%"
	add_child(_label)

	GameEvents.claim_percentage_changed.connect(_update)

	if GameManager.current_level_config:
		set_goal(GameManager.current_level_config.claim_percentage_to_win)


func set_goal(goal_pct: float) -> void:
	_goal = goal_pct
	_goal_marker.position.x = BAR_WIDTH * goal_pct - 1


func _update(percentage: float) -> void:
	var ratio := clampf(percentage, 0.0, 1.0)
	_fill.size.x = BAR_WIDTH * ratio
	_fill.color = Color.GOLD if percentage >= _goal else Color(0.2, 0.6, 1.0)
	_label.text = "%d%%" % roundi(percentage * 100)
