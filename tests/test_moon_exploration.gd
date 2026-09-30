extends SceneTree

var _original_reduced_motion := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_original_reduced_motion = root.get_node("SaveService").load_settings().reduced_motion
	root.get_node("SaveService").load_settings().reduced_motion = false
	var scene := load("res://modes/exploration/MoonExploration.tscn") as PackedScene
	var mode := scene.instantiate()
	root.add_child(mode)
	await process_frame
	var context := ModeContext.new()
	context.mode_id = &"exploration"
	context.destination_id = &"moon"
	mode.present({"mode_context": context})
	mode.world.buddy_position = mode.world.CHEESE
	mode._interact()
	if mode.world.cheese_collected or mode.world.buddy_visible or mode.phase != mode.Phase.ARRIVING:
		_fail("Arrival did not lock interaction and hide the Buddy inside the rocket")
		return
	if not await _wait_for_phase(mode, mode.Phase.PLAYING):
		_fail("Arrival did not hand over control")
		return
	if not mode.world.buddy_visible or mode.world.buddy_position != Vector2(270, 405):
		_fail("Buddy did not finish walking out of the rocket")
		return
	var results: Array[ModeResult] = []
	mode.mode_completed.connect(func(result: ModeResult) -> void: results.append(result))
	mode.world._meep_wait = 0.0
	mode.world._update_meep_walk(0.1)
	mode.world._update_meep_walk(0.5)
	if mode.world.meep_position == mode.world.MEEP:
		_fail("Meep did not begin its occasional walk")
		return
	mode.world.buddy_position = mode.world.meep_position
	mode._interact()
	var talking_position: Vector2 = mode.world.meep_position
	mode.world._update_meep_walk(2.0)
	if not mode.world.is_meep_talking() or mode.world.meep_position != talking_position:
		_fail("Meep moved while talking or did not show speech")
		return
	mode.world.advance_meep_dialogue()
	if mode.world._speech.is_revealing():
		_fail("Advance did not reveal the complete speech line")
		return
	mode.world.close_meep_dialogue()
	if mode.world.meep_rescued or not mode._make_result(&"incomplete").rescued_meeps.is_empty():
		_fail("Hungry Meep was rescued without cheese")
		return
	mode.world.buddy_position = mode.world.CHEESE
	mode._interact()
	mode.world.buddy_position = mode.world.DISCOVERY
	mode._interact()
	mode.world.buddy_position = mode.world.meep_position
	mode._interact()
	if not mode.world._speech.get_node("Panel/Column/Dialogue").text.contains("Thank you"):
		_fail("Fed Meep did not thank the Buddy")
		return
	mode.world.close_meep_dialogue()
	mode._interact()
	if not mode.world._speech.get_node("Panel/Column/Dialogue").text.contains("home"):
		_fail("Already-fed Meep did not use friendship dialogue")
		return
	mode.world.close_meep_dialogue()
	mode.world.buddy_position = mode.world.ROCKET
	mode._interact()
	mode._interact()
	if not results.is_empty() or mode.phase != mode.Phase.BOARDING:
		_fail("Departure returned results before the animation or did not lock input")
		return
	if not await _wait_for_phase(mode, mode.Phase.SHAKING):
		_fail("Rocket did not enter its shake stage")
		return
	if mode.world.buddy_visible or mode.world.cinematic_state != &"shaking":
		_fail("Buddy did not board before the rocket and Meep reactions")
		return
	if not await _wait_for_phase(mode, mode.Phase.LAUNCHING):
		_fail("Rocket did not take off")
		return
	if mode.get_node("DepartureFade").color.a != 0.0:
		_fail("Fade began before takeoff finished")
		return
	if not await _wait_for_phase(mode, mode.Phase.FADING):
		_fail("Departure did not reach the fade stage")
		return
	if mode.world.rocket_position.y > -100.0:
		_fail("Fade began while the rocket was still on screen")
		return
	if not await _wait_for_phase(mode, mode.Phase.FINISHED):
		_fail("Departure did not finish")
		return
	if results.size() != 1 or results[0].status != &"completed":
		_fail("Completed exploration did not emit one completed result")
		return
	if int(results[0].rewards.get("moon_cheese", 0)) != 0 or results[0].discoveries != [&"moon_impact_craters"] or results[0].rescued_meeps != [&"moon_first_meep"]:
		_fail("Result did not consume cheese and record one discovery and one rescue")
		return
	mode._restart()
	if mode.world.cheese_collected or mode.world.discovery_found or mode.world.meep_rescued or mode.world.is_meep_talking() or mode.world.meep_position != mode.world.MEEP or mode.world.buddy_position != Vector2(270, 405):
		_fail("Restart did not reset the demo")
		return
	if mode.phase != mode.Phase.ARRIVING or mode.get_node("DepartureFade").color.a != 0.0:
		_fail("Restart did not reset the fade and start a fresh arrival")
		return
	root.get_node("SaveService").load_settings().reduced_motion = true
	mode._restart()
	if not await _wait_for_phase(mode, mode.Phase.PLAYING):
		_fail("Reduced-motion arrival did not unlock controls")
		return
	mode.world.buddy_position = mode.world.ROCKET
	mode._interact()
	if not await _wait_for_phase(mode, mode.Phase.FINISHED):
		_fail("Reduced-motion departure did not finish")
		return
	if results.size() != 2 or results[1].status != &"incomplete":
		_fail("Early return did not produce one incomplete result")
		return
	root.get_node("SaveService").load_settings().reduced_motion = false
	mode.queue_free()
	await process_frame
	var shell := (load("res://scenes/app/GameShell.tscn") as PackedScene).instantiate()
	root.add_child(shell)
	await process_frame
	shell.screen_router.open("play", {}, false)
	await create_timer(0.5).timeout
	var demo_context := ModeContext.new()
	demo_context.mode_id = &"exploration"
	demo_context.destination_id = &"moon"
	shell.screen_router.open("moon_exploration", {"mode_context": demo_context}, true)
	await create_timer(0.5).timeout
	var integrated_mode = shell.screen_router._active_screen
	if shell.screen_router.active_screen_name() != "moon_exploration":
		_fail("Launcher did not open the exploration mode")
		return
	if not await _wait_for_phase(integrated_mode, integrated_mode.Phase.PLAYING):
		_fail("Integrated mode did not finish its landing")
		return
	integrated_mode.world.buddy_position = integrated_mode.world.CHEESE
	integrated_mode._interact()
	integrated_mode.world.buddy_position = integrated_mode.world.DISCOVERY
	integrated_mode._interact()
	integrated_mode.world.buddy_position = integrated_mode.world.meep_position
	integrated_mode._interact()
	integrated_mode.world.close_meep_dialogue()
	integrated_mode.world.buddy_position = integrated_mode.world.ROCKET
	integrated_mode._interact()
	var departure_deadline := 6.0
	while shell.screen_router.active_screen_name() != "play" and departure_deadline > 0.0:
		await create_timer(0.05).timeout
		departure_deadline -= 0.05
	if shell.screen_router.active_screen_name() != "play":
		_fail("Mode result did not return to the demo launcher")
		return
	if not shell.screen_router._active_screen.get_node("Center/Panel/Content/LastRunLabel").text.contains("completed"):
		_fail("Demo launcher did not display the result")
		return
	shell.screen_router.back()
	await create_timer(0.5).timeout
	if shell.screen_router.active_screen_name() != "title":
		_fail("Back from the demo launcher did not return to title")
		return
	print("Moon exploration contract smoke test passed")
	root.get_node("SaveService").load_settings().reduced_motion = _original_reduced_motion
	quit(0)


func _fail(message: String) -> void:
	root.get_node("SaveService").load_settings().reduced_motion = _original_reduced_motion
	push_error(message)
	quit(1)


func _wait_for_phase(mode: Control, expected: int) -> bool:
	var deadline := 6.0
	while mode.phase != expected and deadline > 0.0:
		await create_timer(0.025).timeout
		deadline -= 0.025
	return mode.phase == expected
