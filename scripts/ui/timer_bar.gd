extends Control
class_name TimerBar
## Compact timer bar below progress bar.

const BAR_WIDTH := 200.0
const BAR_HEIGHT := 8.0

var _fill: ColorRect
var _bg: ColorRect
var _label: Label


func _ready() -> void:
	anchor_left = 0.5
	anchor_top = 0.0
	offset_left = -BAR_WIDTH / 2.0
	offset_top = 24
	size = Vector2(BAR_WIDTH, BAR_HEIGHT + 14)

	_bg = ColorRect.new()
	_bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bg.color = Color(0.1, 0.1, 0.15, 0.8)
	add_child(_bg)

	_fill = ColorRect.new()
	_fill.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_fill.color = Color.GREEN
	add_child(_fill)

	_label = Label.new()
	_label.position = Vector2(BAR_WIDTH + 6, -3)
	_label.add_theme_font_size_override("font_size", 10)
	add_child(_label)

	GameEvents.timer_changed.connect(_update)


func _update(remaining: float, total: float) -> void:
	var ratio := clampf(remaining / maxf(total, 0.1), 0.0, 1.0)
	_fill.size.x = BAR_WIDTH * ratio
	if ratio > 0.5:
		_fill.color = Color.GREEN.lerp(Color.YELLOW, 1.0 - (ratio - 0.5) * 2.0)
	else:
		_fill.color = Color.YELLOW.lerp(Color.RED, 1.0 - ratio * 2.0)
	var mins := int(remaining) / 60
	var secs := int(remaining) % 60
	_label.text = "%d:%02d" % [mins, secs]
