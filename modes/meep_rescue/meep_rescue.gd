extends Control

signal mode_completed(result: ModeResult)

enum Phase { ARRIVING, PLAYING, OPENING, RESCUING, BOARDING, LAUNCHING, FADING, FINISHED }

const WALK_SPEED := 245.0
const INTERACTION_RANGE := 102.0
const ROCKET_DOOR := Vector2(162, 417)

@onready var world: Node2D = $World

var mode_context: ModeContext
var phase := Phase.ARRIVING
var starting_cheese := 0
var cheese_carried := 0
var cheese_collected := 0
var cheese_shared := false
var _message_time := 0.0
var _sequence_tween: Tween
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	%RestartButton.pressed.connect(_restart)
	%ExitButton.pressed.connect(_exit_demo)
	resized.connect(_resize_world)
	_resize_world()
	_rng.randomize()
	if mode_context == null:
		mode_context = _default_context()
	_restart()


func present(context: Dictionary) -> void:
	mode_context = context.get("mode_context") as ModeContext
	if mode_context == null:
		mode_context = _default_context()
	_restart()


func _default_context() -> ModeContext:
	var context := ModeContext.new()
	context.mode_id = &"meep_rescue"
	context.destination_id = &"moon"
	return context


func _resize_world() -> void:
	if world != null:
		world.scale = Vector2(size.x / 1280.0, size.y / 720.0)


func _physics_process(delta: float) -> void:
	if phase != Phase.PLAYING:
		return
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var previous: Vector2 = world.buddy_position
	if movement != Vector2.ZERO:
		world.buddy_facing = movement
		var next_position: Vector2 = world.buddy_position + movement * WALK_SPEED * delta
		next_position.x = clampf(next_position.x, 26.0, 1250.0 if world.rock_open else 739.0)
		next_position.y = clampf(next_position.y, 325.0, 528.0)
		world.buddy_position = next_position
	world.update_walk(previous.distance_to(world.buddy_position), delta)
	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0:
			%FeedbackLabel.text = "Follow the Meep signal. Every rescue starts with a clue."
	_update_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if phase != Phase.PLAYING:
		return
	if event.is_action_pressed("scan"):
		_scan()
	elif event.is_action_pressed("interact"):
		_interact()
	elif event.is_action_pressed("restart_demo"):
		_restart()
	elif event.is_action_pressed("ui_cancel"):
		if world.is_meep_talking():
			world.close_meep_dialogue()
		else:
			_exit_demo()
	else:
		return
	get_viewport().set_input_as_handled()


func _nearest_target() -> String:
	var closest := INTERACTION_RANGE
	var target := ""
	var options := {"rocket": world.ROCKET_SITE, "meep": world.meep_position}
	if world.cheese_visible:
		options["cheese"] = world.CHEESE_SITE
	if not world.rock_open:
		for index in range(3):
			options["rock_%d" % index] = world.rock_position(index)
	for key in options:
		var distance: float = world.buddy_position.distance_to(options[key])
		if distance < closest:
			closest = distance
			target = key
	return target


func _update_prompt() -> void:
	if world.is_meep_talking():
		%PromptLabel.text = "E / A  •  Continue talking     ESC / B  •  Close"
		return
	var target := _nearest_target()
	if target.begins_with("rock_"):
		%PromptLabel.text = "E / A  •  Try Buddy's rock gadget"
		return
	match target:
		"rocket": %PromptLabel.text = "E / A  •  Return to rocket"
		"cheese": %PromptLabel.text = "E / A  •  Pick up Moon Cheese"
		"meep": %PromptLabel.text = "E / A  •  Say hello" if world.meep_rescued else ("E / A  •  Share Moon Cheese" if cheese_carried > 0 else "E / A  •  Comfort the trapped Meep")
		_: %PromptLabel.text = "Q / X  •  Scan for the Meep signal"


func _scan() -> void:
	world.scan_time = 0.85
	if not world.rock_revealed:
		world.rock_revealed = true
		var position_name: String = ["top", "middle", "bottom"][world.weak_rock_index]
		_show_message("Scanner: the %s boulder has a loose seam! Try the gadget there." % position_name, 5.0)
	elif not world.rock_open:
		_show_message("Scanner: the glowing crack marks the loose boulder.", 3.5)
	elif not world.meep_rescued:
		_show_message("Scanner: MEEP signal ahead! A little Moon Cheese may help.", 3.5)
	else:
		_show_message("Scanner: friend found! Bring your Meep back to the rocket.", 3.5)
	world.queue_redraw()
	_update_hud()


func _interact() -> void:
	if world.is_meep_talking():
		world.advance_meep_dialogue()
		return
	var target := _nearest_target()
	if target.begins_with("rock_"):
		_try_rock(int(target.trim_prefix("rock_")))
		return
	match target:
		"rocket": _start_departure()
		"cheese":
			world.cheese_visible = false
			cheese_carried += 1
			cheese_collected += 1
			world.pickup_time = 0.85
			world.queue_redraw()
			_show_message("Moon Cheese acquired! The Meep might like a snack.", 4.0)
		"meep":
			if world.meep_rescued:
				world.say_meep("MEEP! We are rocket buddies now. Let's go home!")
			elif cheese_carried <= 0:
				world.say_meep("Meep... I am stuck, and my tummy is growling.")
				_show_message("This Meep needs help. Look for Moon Cheese nearby.", 4.0)
			else:
				_start_rescue()
		_:
			_show_message("Move closer to a rock, the cheese, the Meep, or the rocket.")
	_update_hud()
	_update_prompt()


func _try_rock(index: int) -> void:
	if not world.rock_revealed:
		world.bonk_rock_index = index
		world.rock_bonk_time = 0.65
		_show_message("BONK! These rocks look alike. Scan to find a loose seam.", 4.0)
	elif index != world.weak_rock_index:
		world.bonk_rock_index = index
		world.rock_bonk_time = 0.65
		_show_message("BONK! That rock will not budge. Try the glowing crack.", 4.0)
	else:
		phase = Phase.OPENING
		world.rock_open = true
		%PromptLabel.text = "THE PATH IS OPENING..."
		_show_message("Buddy's gadget lifts the loose boulder!", 3.0)
		%RestartButton.disabled = true
		%ExitButton.disabled = true
		var reduced := SaveService.is_reduced_motion()
		_sequence_tween = create_tween()
		_sequence_tween.tween_property(world, "rock_move", 1.0, 0.01 if reduced else 0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_sequence_tween.tween_callback(func() -> void:
			phase = Phase.PLAYING
			world.say_meep("MEEP! You found a way through! Is that cheese I smell?")
			%RestartButton.disabled = false
			%ExitButton.disabled = false
			_update_hud()
			_update_prompt()
		)
	world.queue_redraw()


func _start_rescue() -> void:
	phase = Phase.RESCUING
	cheese_carried -= 1
	cheese_shared = true
	world.close_meep_dialogue()
	world.cheese_toss_visible = true
	world.cheese_toss_position = world.buddy_position + Vector2(25, -35)
	world.meep_following = false
	%PromptLabel.text = "SHARING MOON CHEESE..."
	%RestartButton.disabled = true
	%ExitButton.disabled = true
	var reduced := SaveService.is_reduced_motion()
	_sequence_tween = create_tween()
	_sequence_tween.tween_property(world, "cheese_toss_position", world.meep_position + Vector2(0, -30), 0.01 if reduced else 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_sequence_tween.tween_callback(func() -> void:
		world.cheese_toss_visible = false
		world.meep_rescued = true
		world.rescue_time = 2.0
		world.say_meep("MEEP! You saved me! Can I ride in your rocket?")
		world.queue_redraw()
	)
	_sequence_tween.tween_interval(0.2 if reduced else 0.95)
	_sequence_tween.tween_callback(func() -> void:
		world.meep_following = true
		phase = Phase.PLAYING
		%RestartButton.disabled = false
		%ExitButton.disabled = false
		_show_message("Your new Meep friend is following you. Head back to the rocket!", 5.0)
		_update_hud()
		_update_prompt()
	)
	_update_hud()


func _start_departure() -> void:
	if phase != Phase.PLAYING:
		return
	world.close_meep_dialogue()
	phase = Phase.BOARDING
	world.stage = &"boarding"
	world.meep_following = false
	%RestartButton.disabled = true
	%ExitButton.disabled = true
	%PromptLabel.text = "RETURNING TO THE ROCKET..."
	var reduced := SaveService.is_reduced_motion()
	var boarding_time := 0.01 if reduced else clampf(world.buddy_position.distance_to(ROCKET_DOOR) / WALK_SPEED, 0.45, 1.0)
	_sequence_tween = create_tween()
	_sequence_tween.tween_method(world.move_buddy, world.buddy_position, ROCKET_DOOR, boarding_time)
	_sequence_tween.parallel().tween_property(world, "buddy_scale", 0.55, boarding_time)
	if world.meep_rescued:
		_sequence_tween.parallel().tween_property(world, "meep_position", ROCKET_DOOR + Vector2(32, 16), boarding_time)
	_sequence_tween.tween_callback(func() -> void:
		world.buddy_visible = false
		if world.meep_rescued:
			world.meep_visible = false
		world.stage = &"shaking"
		world.queue_redraw()
	)
	_sequence_tween.tween_interval(0.25 if reduced else 0.7)
	_sequence_tween.tween_callback(func() -> void:
		phase = Phase.LAUNCHING
		world.stage = &"launching"
	)
	_sequence_tween.tween_property(world, "rocket_position", Vector2(world.ROCKET_SITE.x, -230), 0.01 if reduced else 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_sequence_tween.tween_callback(func() -> void: phase = Phase.FADING)
	_sequence_tween.tween_property(%Fade, "color:a", 1.0, 0.01 if reduced else 0.45)
	_sequence_tween.tween_callback(func() -> void: _emit_result(_make_result(&"completed" if world.meep_rescued else &"incomplete")))


func _update_hud() -> void:
	%ObjectiveLabel.text = "%s PATH   %s CHEESE   %s MEEP   [ ] RETURN" % [
		"[✓]" if world.rock_open else "[ ]",
		"[✓]" if cheese_carried > 0 or cheese_shared else "[ ]",
		"[✓]" if world.meep_rescued else "[ ]"
	]
	%CheeseLabel.text = "MOON CHEESE  %d" % cheese_carried


func _show_message(message: String, seconds := 3.0) -> void:
	%FeedbackLabel.text = message
	_message_time = seconds


func _make_result(status: StringName) -> ModeResult:
	var result := ModeResult.new()
	result.status = status
	result.rewards = {"moon_cheese": max(0, cheese_collected - (1 if cheese_shared else 0))}
	if cheese_collected > 0:
		result.objective_events.append({"type": &"item_collected", "id": &"moon_cheese", "amount": cheese_collected})
	if cheese_shared:
		result.objective_events.append({"type": &"item_used", "id": &"moon_cheese", "amount": 1})
	if world.rock_open:
		result.objective_events.append({"type": &"path_opened", "id": &"moon_meep_passage"})
	if world.meep_rescued:
		result.rescued_meeps.append(&"moon_first_meep")
		result.objective_events.append({"type": &"meep_rescued", "id": &"moon_first_meep"})
	result.metadata = {"mode_id": mode_context.mode_id, "destination_id": mode_context.destination_id, "starting_cheese": starting_cheese, "cheese_remaining": cheese_carried, "weak_rock_index": world.weak_rock_index}
	return result


func _exit_demo() -> void:
	if phase == Phase.PLAYING:
		_emit_result(_make_result(&"cancelled"))


func _emit_result(result: ModeResult) -> void:
	if phase == Phase.FINISHED:
		return
	phase = Phase.FINISHED
	world.stage = &"finished"
	if mode_completed.get_connections().is_empty():
		print("Meep Rescue result: ", result.status, " ", result.rewards, " ", result.rescued_meeps)
		get_tree().quit()
	else:
		mode_completed.emit(result)


func _restart() -> void:
	if _sequence_tween != null:
		_sequence_tween.kill()
	phase = Phase.ARRIVING
	world.reset()
	starting_cheese = clampi(int(mode_context.parameters.get("moon_cheese", 0)), 0, 9)
	cheese_carried = starting_cheese
	cheese_collected = 0
	cheese_shared = false
	world.cheese_visible = cheese_carried == 0
	var chosen_index := int(mode_context.parameters.get("weak_rock_index", -1))
	world.weak_rock_index = chosen_index if chosen_index >= 0 and chosen_index < 3 else _rng.randi_range(0, 2)
	_message_time = 0.0
	%Fade.color.a = 0.0
	%FeedbackLabel.text = "A faint MEEP is coming from beyond the rocks."
	%PromptLabel.text = "LANDING NEAR THE MEEP SIGNAL..."
	%RestartButton.disabled = true
	%ExitButton.disabled = true
	_update_hud()
	world.buddy_visible = false
	world.rocket_position = Vector2(world.ROCKET_SITE.x, -230)
	world.stage = &"arriving"
	var reduced := SaveService.is_reduced_motion()
	_sequence_tween = create_tween()
	_sequence_tween.tween_property(world, "rocket_position", world.ROCKET_SITE, 0.01 if reduced else 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_sequence_tween.tween_interval(0.15)
	_sequence_tween.tween_callback(func() -> void:
		world.buddy_position = ROCKET_DOOR
		world.buddy_scale = 0.55
		world.buddy_visible = true
	)
	_sequence_tween.tween_method(world.move_buddy, ROCKET_DOOR, world.BUDDY_START, 0.01 if reduced else 0.65)
	_sequence_tween.parallel().tween_property(world, "buddy_scale", 1.0, 0.01 if reduced else 0.65)
	_sequence_tween.tween_callback(func() -> void:
		world.stage = &"playing"
		phase = Phase.PLAYING
		%RestartButton.disabled = false
		%ExitButton.disabled = false
		_update_prompt()
	)
