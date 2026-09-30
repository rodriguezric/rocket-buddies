extends SceneTree

var _original_reduced_motion := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var save_service = root.get_node("SaveService")
	_original_reduced_motion = save_service.load_settings().reduced_motion
	save_service.load_settings().reduced_motion = true
	var mode = (load("res://modes/flight/RocketFlight.tscn") as PackedScene).instantiate()
	root.add_child(mode)
	await process_frame
	if not await _wait_for_phase(mode, mode.Phase.FLYING):
		_fail("Flight launch did not hand over control")
		return
	var results: Array[ModeResult] = []
	mode.mode_completed.connect(func(result: ModeResult) -> void: results.append(result))
	mode.world.entities.append({"kind": &"stardust", "position": Vector2(1100, 365), "spin": 0.0, "spin_rate": 0.0})
	var route_start: float = mode.elapsed
	var item_start: float = mode.world.entities[0]["position"].x
	var scroll_start: float = mode.world._star_scroll
	mode._physics_process(0.1)
	var normal_route: float = mode.elapsed - route_start
	var normal_item: float = item_start - mode.world.entities[0]["position"].x
	var normal_scroll: float = mode.world._star_scroll - scroll_start
	Input.action_press("boost")
	route_start = mode.elapsed
	item_start = mode.world.entities[0]["position"].x
	scroll_start = mode.world._star_scroll
	mode._physics_process(0.1)
	Input.action_release("boost")
	if not is_equal_approx(mode.elapsed - route_start, normal_route * mode.BOOST_MULTIPLIER) or not is_equal_approx(item_start - mode.world.entities[0]["position"].x, normal_item * mode.BOOST_MULTIPLIER) or not is_equal_approx(mode.world._star_scroll - scroll_start, normal_scroll * mode.BOOST_MULTIPLIER):
		_fail("Boost did not speed route progress, pickups, and stars equally")
		return
	mode.world.comet_time = 2.2
	mode.world.ship_position = mode.world.get_comet_position()
	mode._check_collisions()
	if mode.moon_cheese != 1 or mode.world.comet_time != 0.0:
		_fail("Touching the Moon Cheese comet did not collect it")
		return
	mode.world.entities.clear()
	mode.world.entities.append({"kind": &"stardust", "position": mode.world.ship_position, "spin": 0.0, "spin_rate": 0.0})
	mode._check_collisions()
	mode.world.entities.append({"kind": &"fuel", "position": mode.world.ship_position, "spin": 0.0, "spin_rate": 0.0})
	mode._check_collisions()
	mode.world.entities.append({"kind": &"asteroid", "position": mode.world.ship_position, "spin": 0.0, "spin_rate": 0.0})
	mode._check_collisions()
	if mode.stardust != 1 or not is_equal_approx(mode.fuel, 77.2) or mode.bumps != 1:
		_fail("Flight pickups or bumper fuel loss produced the wrong state")
		return
	mode._restart()
	if mode.stardust != 0 or mode.bumps != 0 or mode.fuel != 68.0 or not mode.world.entities.is_empty():
		_fail("Flight restart did not clear the previous run")
		return
	if not await _wait_for_phase(mode, mode.Phase.FLYING):
		_fail("Flight restart did not return to flying")
		return
	mode.stardust = 3
	mode.moon_cheese = 1
	mode.elapsed = mode.FLIGHT_SECONDS - 0.01
	await process_frame
	if not await _wait_for_phase(mode, mode.Phase.FINISHED):
		_fail("Flight did not finish its Moon arrival")
		return
	if results.size() != 1 or results[0].status != &"completed" or int(results[0].rewards.get("stardust", -1)) != 3 or int(results[0].rewards.get("moon_cheese", -1)) != 1:
		_fail("Flight emitted an incorrect completion result")
		return
	if results[0].objective_events.size() != 3 or results[0].metadata.get("destination_id") != &"moon":
		_fail("Flight result lost its destination or objective events")
		return
	mode.queue_free()
	await process_frame
	var shell = (load("res://scenes/app/GameShell.tscn") as PackedScene).instantiate()
	root.add_child(shell)
	await process_frame
	await create_timer(0.65).timeout
	shell.screen_router.open("play", {}, false)
	await create_timer(0.05).timeout
	shell.screen_router._active_screen._launch_flight()
	await create_timer(0.05).timeout
	if shell.screen_router.active_screen_name() != "rocket_flight":
		_fail("Demo launcher did not open Rocket Flight")
		return
	var integrated_mode = shell.screen_router._active_screen
	if not await _wait_for_phase(integrated_mode, integrated_mode.Phase.FLYING):
		_fail("Integrated flight did not hand over control")
		return
	integrated_mode._exit_demo()
	await create_timer(0.05).timeout
	if shell.screen_router.active_screen_name() != "play":
		_fail("Flight result did not return to the demo launcher")
		return
	if not shell.screen_router._active_screen.get_node("Center/Panel/Content/LastRunLabel").text.contains("cancelled flight"):
		_fail("Demo launcher did not show the flight result")
		return
	shell.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	save_service.load_settings().reduced_motion = _original_reduced_motion
	print("Rocket Flight contract smoke test passed")
	quit(0)


func _wait_for_phase(mode: Control, expected: int) -> bool:
	var deadline := 3.0
	while mode.phase != expected and deadline > 0.0:
		await create_timer(0.025).timeout
		deadline -= 0.025
	return mode.phase == expected


func _fail(message: String) -> void:
	root.get_node("SaveService").load_settings().reduced_motion = _original_reduced_motion
	push_error(message)
	quit(1)
