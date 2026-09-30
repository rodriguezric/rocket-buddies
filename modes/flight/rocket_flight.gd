extends Control

signal mode_completed(result: ModeResult)

enum Phase { LAUNCHING, FLYING, ARRIVING, FADING, FINISHED }

const FLIGHT_SECONDS := 48.0
const SHIP_SPEED := 315.0
const FUEL_CAPACITY := 100.0
const BOOST_MULTIPLIER := 2.0
const LANES := [215.0, 290.0, 365.0, 440.0, 515.0]

@onready var world: Node2D = $World

var mode_context: ModeContext
var phase := Phase.LAUNCHING
var fuel := 68.0
var stardust := 0
var moon_cheese := 0
var bumps := 0
var elapsed := 0.0
var _spawn_time := 0.0
var _spawn_index := 0
var _radio_shown := false
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
	context.mode_id = &"flight"
	context.destination_id = &"moon"
	return context


func _resize_world() -> void:
	if world != null:
		world.scale = Vector2(size.x / 1280.0, size.y / 720.0)


func _physics_process(delta: float) -> void:
	if phase != Phase.FLYING:
		world.update_world(delta)
		return
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var boosting := Input.is_action_pressed("boost") and fuel > 0.0
	var travel_speed := 1.0
	if boosting:
		fuel = maxf(0.0, fuel - 8.0 * delta)
		travel_speed = BOOST_MULTIPLIER
	elif fuel <= 0.0:
		travel_speed = 0.75
	world.speed_factor = travel_speed
	world.update_world(delta)
	world.ship_position += movement * SHIP_SPEED * delta
	world.ship_position.x = clampf(world.ship_position.x, 155.0, 615.0)
	world.ship_position.y = clampf(world.ship_position.y, 190.0, 555.0)
	var target_tilt := movement.y * 0.11
	world.ship_tilt = target_tilt if SaveService.is_reduced_motion() else lerpf(world.ship_tilt, target_tilt, minf(delta * 7.0, 1.0))
	elapsed = minf(FLIGHT_SECONDS, elapsed + delta * travel_speed)
	world.flight_progress = elapsed / FLIGHT_SECONDS
	_spawn_time += delta * travel_speed
	if _spawn_time >= 1.15 and elapsed < FLIGHT_SECONDS - 2.0:
		_spawn_time -= 1.15
		_spawn_entity()
	_check_collisions()
	if not _radio_shown and elapsed >= 17.0:
		_radio_shown = true
		world.comet_time = 4.4
		_show_message("RADIO: A Moon Cheese comet! Steer into it for a snack, Buddy!", 4.5)
	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0:
			%FeedbackLabel.text = "Catch stardust and fuel. Dodge the bouncy space rocks!"
	_update_hud()
	if elapsed >= FLIGHT_SECONDS:
		_start_arrival()


func _unhandled_input(event: InputEvent) -> void:
	if phase != Phase.FLYING:
		return
	if event.is_action_pressed("restart_demo"):
		_restart()
	elif event.is_action_pressed("ui_cancel"):
		_exit_demo()
	else:
		return
	get_viewport().set_input_as_handled()


func _spawn_entity() -> void:
	_spawn_index += 1
	var kind: StringName = &"stardust"
	if _spawn_index == 5 or _spawn_index == 24:
		kind = &"fuel"
	elif _spawn_index % 3 == 0 or _rng.randf() < 0.25:
		kind = &"asteroid"
	var lane: float = LANES[_rng.randi_range(0, LANES.size() - 1)]
	# The first pickup follows the starting lane so players learn the collection loop.
	if _spawn_index == 1:
		lane = 365.0
	world.entities.append({"kind": kind, "position": Vector2(1340.0, lane), "spin": 0.0, "spin_rate": _rng.randf_range(-1.5, 1.5)})


func _check_collisions() -> void:
	if moon_cheese == 0 and world.comet_time > 0.0 and world.ship_position.distance_to(world.get_comet_position()) < 78.0:
		moon_cheese = 1
		world.comet_time = 0.0
		world.pickup_time = 0.8
		world.burst(world.ship_position, Color("f9cb65"), "MOON CHEESE!")
		_show_message("Moon Cheese comet collected! The radio says, ‘Nice catch!’", 3.5)
	for index in range(world.entities.size() - 1, -1, -1):
		var entity: Dictionary = world.entities[index]
		var kind: StringName = entity["kind"]
		var position: Vector2 = entity["position"]
		var reach := 57.0 if kind == &"asteroid" else 55.0
		if world.ship_position.distance_to(position) > reach:
			continue
		if kind == &"asteroid" and world.invulnerable_time > 0.0:
			continue
		world.entities.remove_at(index)
		match kind:
			&"stardust":
				stardust += 1
				world.pickup_time = 0.5
				world.burst(position, world.GOLD, "+1 STAR")
				_show_message("Stardust tucked safely in the glove box!", 2.5)
			&"fuel":
				fuel = minf(FUEL_CAPACITY, fuel + 24.0)
				world.pickup_time = 0.65
				world.burst(position, world.TEAL, "+FUEL")
				_show_message("Fuel tank topped up. Moonward we go!", 2.5)
			&"asteroid":
				bumps += 1
				fuel = maxf(0.0, fuel - 14.0)
				world.impact_time = 0.5
				world.invulnerable_time = 1.5
				world.burst(position, world.CORAL, "BONK!")
				_show_message("Boing! The bumper held. Keep flying!", 2.5)
		world.queue_redraw()


func _show_message(message: String, seconds: float) -> void:
	%FeedbackLabel.text = message
	_message_time = seconds


func _update_hud() -> void:
	%ProgressBar.value = world.flight_progress * 100.0
	%ProgressLabel.text = "%d%% TO THE MOON" % roundi(world.flight_progress * 100.0)
	%FuelBar.value = fuel
	%FuelLabel.text = "FUEL  %d" % ceili(fuel)
	%StardustLabel.text = "STARDUST  %d" % stardust
	%CheeseLabel.text = "MOON CHEESE  %d" % moon_cheese


func _make_result(status: StringName) -> ModeResult:
	var result := ModeResult.new()
	result.status = status
	result.rewards = {"stardust": stardust, "moon_cheese": moon_cheese}
	if status == &"completed":
		result.objective_events.append({"type": &"destination_arrived", "id": mode_context.destination_id})
	if stardust > 0:
		result.objective_events.append({"type": &"item_collected", "id": &"stardust", "amount": stardust})
	if moon_cheese > 0:
		result.objective_events.append({"type": &"item_collected", "id": &"moon_cheese", "amount": moon_cheese})
	result.metadata = {"mode_id": mode_context.mode_id, "destination_id": mode_context.destination_id, "fuel_remaining": ceili(fuel), "bumps": bumps}
	return result


func _restart() -> void:
	if _sequence_tween != null:
		_sequence_tween.kill()
	phase = Phase.LAUNCHING
	fuel = 68.0
	stardust = 0
	moon_cheese = 0
	bumps = 0
	elapsed = 0.0
	_spawn_time = 0.0
	_spawn_index = 0
	_radio_shown = false
	_message_time = 0.0
	world.reset()
	%Fade.color.a = 0.0
	%TitleLabel.text = "ROCKET FLIGHT"
	%FeedbackLabel.text = "Buckle up, Buddy. The Moon is waiting!"
	%PromptLabel.text = "LAUNCHING..."
	%RestartButton.disabled = true
	%ExitButton.disabled = true
	_update_hud()
	var reduced := SaveService.is_reduced_motion()
	_sequence_tween = create_tween()
	_sequence_tween.tween_property(world, "ship_position", Vector2(300, 365), 0.01 if reduced else 1.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_sequence_tween.tween_callback(func() -> void:
		phase = Phase.FLYING
		world.stage = &"flying"
		%PromptLabel.text = "WASD / STICK  •  STEER     SHIFT / RB  •  BOOST"
		%RestartButton.disabled = false
		%ExitButton.disabled = false
	)


func _start_arrival() -> void:
	if phase != Phase.FLYING:
		return
	phase = Phase.ARRIVING
	world.stage = &"arriving"
	world.entities.clear()
	world.queue_redraw()
	%PromptLabel.text = "THE MOON IS RIGHT AHEAD!"
	%FeedbackLabel.text = "Touchdown time! Nice flying, Buddy."
	%RestartButton.disabled = true
	%ExitButton.disabled = true
	var reduced := SaveService.is_reduced_motion()
	_sequence_tween = create_tween()
	_sequence_tween.tween_property(world, "ship_position", Vector2(965, 365), 0.01 if reduced else 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_sequence_tween.parallel().tween_property(world, "ship_scale", 0.38, 0.01 if reduced else 2.0)
	_sequence_tween.tween_callback(func() -> void: phase = Phase.FADING)
	_sequence_tween.tween_property(%Fade, "color:a", 1.0, 0.01 if reduced else 0.65)
	_sequence_tween.tween_callback(func() -> void: _emit_result(_make_result(&"completed")))


func _exit_demo() -> void:
	if phase == Phase.FLYING:
		_emit_result(_make_result(&"cancelled"))


func _emit_result(result: ModeResult) -> void:
	if phase == Phase.FINISHED:
		return
	phase = Phase.FINISHED
	world.stage = &"finished"
	if mode_completed.get_connections().is_empty():
		print("Flight demo result: ", result.status, " ", result.rewards, " ", result.metadata)
		get_tree().quit()
	else:
		mode_completed.emit(result)
