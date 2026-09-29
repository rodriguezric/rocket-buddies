extends Control

signal back_requested
signal navigation_requested(screen_name: String, context: Dictionary, remember: bool)


func _ready() -> void:
	%BackButton.pressed.connect(func() -> void: back_requested.emit())
	%LaunchButton.pressed.connect(_launch_moon)


func present(context: Dictionary) -> void:
	var result: ModeResult = context.get("last_result") as ModeResult
	if result != null:
		%LastRunLabel.text = "Last run: %s  |  Cheese: %d  |  Discovery: %s" % [
			result.status, int(result.rewards.get("moon_cheese", 0)),
			"yes" if not result.discoveries.is_empty() else "no"
		]


func _launch_moon() -> void:
	var context := ModeContext.new()
	context.mode_id = &"exploration"
	context.destination_id = &"moon"
	navigation_requested.emit("moon_exploration", {"mode_context": context}, true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()


func get_initial_focus() -> Control:
	return %LaunchButton
