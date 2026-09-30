extends Control

signal mode_completed(result: ModeResult)

const WALK_SPEED := 245.0
const INTERACTION_RANGE := 92.0

@onready var world: Node2D = $World

var mode_context: ModeContext
var _cheese_collected := false
var _cheese_available := false
var _meep_rescued := false
var _discovery_found := false
var _message_time := 0.0
var _discovery_tween: Tween


func _ready() -> void:
	%RestartButton.pressed.connect(_restart)
	%ExitButton.pressed.connect(_exit_demo)
	%DiscoveryCloseButton.pressed.connect(_hide_discovery_card)
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
	var previous_position: Vector2 = world.buddy_position
	if movement != Vector2.ZERO:
		world.buddy_facing = movement
		var next_position: Vector2 = world.buddy_position + movement * WALK_SPEED * delta
		# Keep the Buddy on the compact playable Moon surface.
		next_position.x = clampf(next_position.x, 28.0, 1252.0)
		next_position.y = clampf(next_position.y, 330.0, 530.0)
		world.buddy_position = next_position
		world.queue_redraw()
	world.update_walk_animation(previous_position.distance_to(world.buddy_position), delta, SaveService.is_reduced_motion())
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
		if world.is_meep_talking():
			world.close_meep_dialogue()
		elif %DiscoveryCard.visible:
			_hide_discovery_card()
		else:
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
		"meep": world.meep_position,
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
	if world.is_meep_talking():
		%PromptLabel.text = "E / A  •  Continue talking     ESC / B  •  Close"
		return
	match _nearest_target():
		"rocket": %PromptLabel.text = "E / A  •  Return to rocket"
		"cheese": %PromptLabel.text = "E / A  •  Collect Moon Cheese"
		"crater": %PromptLabel.text = "E / A  •  Inspect crater"
		"meep":
			%PromptLabel.text = "E / A  •  Say hello to your Meep friend" if _meep_rescued else ("E / A  •  Offer Moon Cheese" if _cheese_available else "E / A  •  Meet the hungry Meep")
		_: %PromptLabel.text = "Q / X  •  Scan for clues"


func _scan() -> void:
	world.play_scan()
	var clues: Array[String] = []
	if not _cheese_collected:
		clues.append("Cheese signal %s" % _direction_to(world.CHEESE))
	if not _discovery_found:
		clues.append("Interesting crater %s" % _direction_to(world.DISCOVERY))
	if not _meep_rescued:
		clues.append("Meep signal %s" % _direction_to(world.meep_position))
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
	if world.is_meep_talking():
		world.advance_meep_dialogue()
		return
	match _nearest_target():
		"cheese":
			_cheese_collected = true
			_cheese_available = true
			world.cheese_collected = true
			world.play_cheese_pickup()
			_show_message("Moon Cheese collected! It smells mysteriously delicious.", 4.0)
		"crater":
			_discovery_found = true
			world.discovery_found = true
			world.queue_redraw()
			_show_discovery_card()
			_show_message("Moon craters discovered! Inspect the crater again to read the card.", 5.0)
		"rocket":
			_finish()
		"meep":
			_hide_discovery_card()
			if _meep_rescued:
				world.say_meep("Meep! My tummy is happy. Can I come home with you?")
				_show_message("MEEP! Your new friend is ready to go home with you.", 4.0)
			elif _cheese_available:
				_cheese_available = false
				_meep_rescued = true
				world.rescue_meep()
				world.say_meep("MEEP! Cheese! Thank you, Buddy. You are my new friend!")
				_show_message("You shared your cheese! The happy Meep will come home with you.", 6.0)
			else:
				world.say_meep("Meep... my tummy is rumbling. Could you find me some cheese?")
				_show_message("This Meep is hungry! Find Moon Cheese, then bring it back.", 5.0)
		_:
			_show_message("Move closer to something interesting, or scan for clues.")
	_update_hud()


func _update_hud() -> void:
	%ObjectiveLabel.text = "%s CHEESE   %s CRATER   %s MEEP" % [
		"[✓]" if _cheese_collected else "[ ]",
		"[✓]" if _discovery_found else "[ ]",
		"[✓]" if _meep_rescued else "[ ]"
	]


func _show_message(message: String, seconds := 3.0) -> void:
	%FeedbackLabel.text = message
	_message_time = seconds


func _show_discovery_card() -> void:
	if _discovery_tween != null:
		_discovery_tween.kill()
	%DiscoveryCard.show()
	%DiscoveryCard.modulate.a = 1.0
	if not SaveService.is_reduced_motion():
		%DiscoveryCard.modulate.a = 0.0
		_discovery_tween = create_tween()
		_discovery_tween.tween_property(%DiscoveryCard, "modulate:a", 1.0, 0.2)


func _hide_discovery_card() -> void:
	if _discovery_tween != null:
		_discovery_tween.kill()
		_discovery_tween = null
	%DiscoveryCard.hide()
	%DiscoveryCard.modulate.a = 1.0
	if %DiscoveryCloseButton.has_focus():
		%DiscoveryCloseButton.release_focus()


func _make_result(status: StringName) -> ModeResult:
	var result := ModeResult.new()
	result.status = status
	result.rewards = {"moon_cheese": 1 if _cheese_available else 0}
	if _meep_rescued:
		result.rescued_meeps.append(&"moon_first_meep")
		result.objective_events.append({"type": &"meep_rescued", "id": &"moon_first_meep"})
		result.objective_events.append({"type": &"item_used", "id": &"moon_cheese", "amount": 1})
	if _cheese_collected:
		result.objective_events.append({"type": &"item_collected", "id": &"moon_cheese", "amount": 1})
	if _discovery_found:
		result.discoveries.append(&"moon_impact_craters")
		result.objective_events.append({"type": &"discovery_found", "id": &"moon_impact_craters"})
	result.metadata = {"mode_id": mode_context.mode_id, "destination_id": mode_context.destination_id}
	return result


func _finish() -> void:
	var status: StringName = &"completed" if _cheese_collected and _discovery_found and _meep_rescued else &"incomplete"
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
	_hide_discovery_card()
	_cheese_collected = false
	_cheese_available = false
	_meep_rescued = false
	_discovery_found = false
	_message_time = 0.0
	world.buddy_position = Vector2(270, 405)
	world.reset_walk_animation()
	world.reset_pickup_effect()
	world.reset_meep()
	world.cheese_collected = false
	world.discovery_found = false
	world.reset_scan_effect()
	world.queue_redraw()
	%FeedbackLabel.text = "Scan to find something interesting."
	_update_hud()
