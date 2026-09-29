extends Control

signal mode_completed(result: ModeResult)

const WALK_SPEED := 245.0
const INTERACTION_RANGE := 92.0
const SCAN_DURATION := 0.55

@onready var world: Node2D = $World

var mode_context: ModeContext
var _cheese_collected := false
var _discovery_found := false
var _scan_time := 0.0
var _message_time := 0.0


func _ready() -> void:
	%RestartButton.pressed.connect(_restart)
	%ExitButton.pressed.connect(_exit_demo)
	resized.connect(_resize_world)
	_resize_world()
	if mode_context == null:
		mode_context = ModeContext.new()
		mode_context.mode_id = &"exploration"
		mode_context.destination_id = &"moon"
	_update_hud()


func present(context: Dictionary) -> void:
	mode_context = context.get("mode_context") as ModeContext
	if mode_context == null:
		mode_context = ModeContext.new()
		mode_context.mode_id = &"exploration"
		mode_context.destination_id = &"moon"
	_restart()


func _resize_world() -> void:
	if world != null:
		world.scale = Vector2(size.x / 1280.0, size.y / 720.0)


func _physics_process(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if movement != Vector2.ZERO:
		world.buddy_facing = movement
		var next_position: Vector2 = world.buddy_position + movement * WALK_SPEED * delta
		# Keep the Buddy on the compact playable Moon surface.
		next_position.x = clampf(next_position.x, 28.0, 1252.0)
		next_position.y = clampf(next_position.y, 330.0, 530.0)
		world.buddy_position = next_position
		world.queue_redraw()
	if _scan_time > 0.0:
		_scan_time = maxf(0.0, _scan_time - delta)
		world.scan_radius = (SCAN_DURATION - _scan_time) / SCAN_DURATION * 300.0 if _scan_time > 0.0 else 0.0
		world.queue_redraw()
	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0:
			%FeedbackLabel.text = "Scan to look for clues. Return to the rocket when ready."
	_update_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("scan"):
		_scan()
	elif event.is_action_pressed("interact"):
		_interact()
	elif event.is_action_pressed("restart_demo"):
		_restart()
	elif event.is_action_pressed("ui_cancel"):
		_exit_demo()
	else:
		return
	get_viewport().set_input_as_handled()


func _nearest_target() -> String:
	var closest := INTERACTION_RANGE
	var target := ""
	var targets := {
		"rocket": world.ROCKET,
		"cheese": world.CHEESE,
		"crater": world.DISCOVERY,
	}
	for key in targets:
		if key == "cheese" and _cheese_collected:
			continue
		var distance: float = world.buddy_position.distance_to(targets[key])
		if distance < closest:
			closest = distance
			target = key
	return target


func _update_prompt() -> void:
	match _nearest_target():
		"rocket": %PromptLabel.text = "E / A  •  Return to rocket"
		"cheese": %PromptLabel.text = "E / A  •  Collect Moon Cheese"
		"crater": %PromptLabel.text = "E / A  •  Inspect crater"
		_: %PromptLabel.text = "Q / X  •  Scan for clues"


func _scan() -> void:
	_scan_time = SCAN_DURATION
	world.scan_radius = 1.0
	world.queue_redraw()
	var clues: Array[String] = []
	if not _cheese_collected:
		clues.append("Cheese signal %s" % _direction_to(world.CHEESE))
	if not _discovery_found:
		clues.append("Interesting crater %s" % _direction_to(world.DISCOVERY))
	if clues.is_empty():
		_show_message("Everything found! Head back to the rocket.")
	else:
		_show_message("Scanner: " + "  •  ".join(clues))


func _direction_to(target: Vector2) -> String:
	var offset: Vector2 = target - world.buddy_position
	if absf(offset.x) > absf(offset.y):
		return "RIGHT →" if offset.x > 0.0 else "LEFT ←"
	return "DOWN ↓" if offset.y > 0.0 else "UP ↑"


func _interact() -> void:
	match _nearest_target():
		"cheese":
			_cheese_collected = true
			world.cheese_collected = true
			world.queue_redraw()
			_show_message("Moon Cheese collected! It smells mysteriously delicious.", 4.0)
		"crater":
			_discovery_found = true
			world.discovery_found = true
			world.queue_redraw()
			_show_message("Discovery: Most lunar craters formed when space rocks hit the Moon.", 7.0)
		"rocket":
			_finish()
		_:
			_show_message("Move closer to something interesting, or scan for clues.")
	_update_hud()


func _update_hud() -> void:
	%ObjectiveLabel.text = "%s MOON CHEESE     %s CRATER" % [
		"[✓]" if _cheese_collected else "[ ]",
		"[✓]" if _discovery_found else "[ ]"
	]


func _show_message(message: String, seconds := 3.0) -> void:
	%FeedbackLabel.text = message
	_message_time = seconds


func _make_result(status: StringName) -> ModeResult:
	var result := ModeResult.new()
	result.status = status
	result.rewards = {"moon_cheese": 1 if _cheese_collected else 0}
	if _cheese_collected:
		result.objective_events.append({"type": &"item_collected", "id": &"moon_cheese", "amount": 1})
	if _discovery_found:
		result.discoveries.append(&"moon_impact_craters")
		result.objective_events.append({"type": &"discovery_found", "id": &"moon_impact_craters"})
	result.metadata = {"mode_id": mode_context.mode_id, "destination_id": mode_context.destination_id}
	return result


func _finish() -> void:
	var status: StringName = &"completed" if _cheese_collected and _discovery_found else &"incomplete"
	_emit_result(_make_result(status))


func _exit_demo() -> void:
	_emit_result(_make_result(&"cancelled"))


func _emit_result(result: ModeResult) -> void:
	if mode_completed.get_connections().is_empty():
		print("Moon demo result: ", result.status, " ", result.rewards, " ", result.discoveries)
		get_tree().quit()
	else:
		mode_completed.emit(result)


func _restart() -> void:
	_cheese_collected = false
	_discovery_found = false
	_scan_time = 0.0
	_message_time = 0.0
	world.buddy_position = Vector2(270, 405)
	world.cheese_collected = false
	world.discovery_found = false
	world.scan_radius = 0.0
	world.queue_redraw()
	%FeedbackLabel.text = "Scan to find something interesting."
	_update_hud()
