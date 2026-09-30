extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://modes/exploration/MoonExploration.tscn") as PackedScene
	var mode := scene.instantiate()
	root.add_child(mode)
	await process_frame
	var context := ModeContext.new()
	context.mode_id = &"exploration"
	context.destination_id = &"moon"
	mode.present({"mode_context": context})
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
	integrated_mode.world.buddy_position = integrated_mode.world.CHEESE
	integrated_mode._interact()
	integrated_mode.world.buddy_position = integrated_mode.world.DISCOVERY
	integrated_mode._interact()
	integrated_mode.world.buddy_position = integrated_mode.world.meep_position
	integrated_mode._interact()
	integrated_mode.world.close_meep_dialogue()
	integrated_mode.world.buddy_position = integrated_mode.world.ROCKET
	integrated_mode._interact()
	await create_timer(0.5).timeout
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
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
