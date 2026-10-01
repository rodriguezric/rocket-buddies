extends Control

signal back_requested
signal navigation_requested(screen_name: String, context: Dictionary, remember: bool)


func _ready() -> void:
	%BackButton.pressed.connect(func() -> void: back_requested.emit())
	%LaunchButton.pressed.connect(_launch_moon)
	%FlightButton.pressed.connect(_launch_flight)
	%HuntButton.pressed.connect(_launch_hunt)


func present(context: Dictionary) -> void:
	var result: ModeResult = context.get("last_result") as ModeResult
	if result != null:
		if result.metadata.get("mode_id") == &"cheese_hunt":
			%LastRunLabel.text = "%s hunt  |  Cheese: %d  |  Scans: %d  |  Digs: %d" % [
				result.status, int(result.rewards.get("moon_cheese", 0)), int(result.metadata.get("scans_used", 0)), int(result.metadata.get("digs_used", 0))
			]
		elif result.metadata.get("mode_id") == &"flight":
			%LastRunLabel.text = "%s flight  |  Stardust: %d  |  Cheese: %d  |  Fuel: %d" % [
				result.status, int(result.rewards.get("stardust", 0)), int(result.rewards.get("moon_cheese", 0)), int(result.metadata.get("fuel_remaining", 0))
			]
		else:
			%LastRunLabel.text = "%s  |  Cheese: %d  |  Discovery: %s  |  Meeps: %d" % [
				result.status, int(result.rewards.get("moon_cheese", 0)),
				"yes" if not result.discoveries.is_empty() else "no", result.rescued_meeps.size()
			]


func _launch_moon() -> void:
	var context := ModeContext.new()
	context.mode_id = &"exploration"
	context.destination_id = &"moon"
	navigation_requested.emit("moon_exploration", {"mode_context": context}, true)


func _launch_flight() -> void:
	var context := ModeContext.new()
	context.mode_id = &"flight"
	context.destination_id = &"moon"
	navigation_requested.emit("rocket_flight", {"mode_context": context}, true)


func _launch_hunt() -> void:
	var context := ModeContext.new()
	context.mode_id = &"cheese_hunt"
	context.destination_id = &"moon"
	navigation_requested.emit("moon_cheese_hunt", {"mode_context": context}, true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()


func get_initial_focus() -> Control:
	return %LaunchButton
