extends Node

const REQUIRED_ACTIONS := [&"ui_accept", &"ui_cancel"]


func _ready() -> void:
	for action in REQUIRED_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)


func binding_summary() -> String:
	return "Confirm: Space / Enter / controller south\nBack: Escape / controller east"


func reset_to_project_defaults() -> void:
	InputMap.load_from_project_settings()
