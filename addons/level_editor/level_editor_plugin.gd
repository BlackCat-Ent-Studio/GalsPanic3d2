@tool
extends EditorPlugin
## Registers the Level Editor bottom panel in the Godot Editor.

var _panel: Control


func _enter_tree() -> void:
	_panel = preload("res://addons/level_editor/level_editor_panel.gd").new()
	_panel.name = "LevelEditor"
	add_control_to_bottom_panel(_panel, "Level Editor")


func _exit_tree() -> void:
	if _panel:
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()
		_panel = null
