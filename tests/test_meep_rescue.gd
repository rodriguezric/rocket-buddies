extends SceneTree

var _original_reduced_motion := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var save_service = root.get_node("SaveService")
	_original_reduced_motion = save_service.load_settings().reduced_motion
	save_service.load_settings().reduced_motion = true
	var mode = (load("res://modes/meep_rescue/MeepRescue.tscn") as PackedScene).instantiate()
	root.add_child(mode)
	await process_frame
	var context := ModeContext.new()
	context.mode_id = &"meep_rescue"
	context.destination_id = &"moon"
	context.parameters = {"weak_rock_index": 2}
	mode.present({"mode_context": context})
	if not await _wait_for_phase(mode, mode.Phase.PLAYING):
		_fail("Meep Rescue landing did not unlock controls")
		return
	var results: Array[ModeResult] = []
	mode.mode_completed.connect(func(result: ModeResult) -> void: results.append(result))
	mode._scan()
	if not mode.world.rock_revealed or mode.world.weak_rock_index != 2:
		_fail("Scanner did not reveal the configured loose boulder")
		return
	mode.world.buddy_position = mode.world.rock_position(0) + Vector2(-58, 0)
	mode._interact()
	if mode.world.rock_open or mode.world.rock_bonk_time <= 0.0:
		_fail("The solid boulder opened the path")
		return
	mode.world.buddy_position = mode.world.rock_position(2) + Vector2(-58, 0)
	mode._interact()
	if not await _wait_for_phase(mode, mode.Phase.PLAYING) or not mode.world.rock_open:
		_fail("The loose boulder did not open the path")
		return
	mode.world.close_meep_dialogue()
	mode.world.buddy_position = mode.world.CHEESE_SITE
	mode._interact()
	if mode.cheese_carried != 1 or mode.world.cheese_visible:
		_fail("Moon Cheese pickup did not enter inventory")
		return
	mode.world.buddy_position = mode.world.MEEP_SITE
	mode._interact()
	if not await _wait_for_phase(mode, mode.Phase.PLAYING):
		_fail("Sharing cheese did not finish the rescue animation")
		return
	if not mode.world.meep_rescued or not mode.world.meep_following or mode.cheese_carried != 0:
		_fail("Meep did not join Buddy after eating cheese")
		return
	mode.world.close_meep_dialogue()
	mode.world.buddy_position = mode.world.ROCKET_SITE
	mode._interact()
	if not await _wait_for_phase(mode, mode.Phase.FINISHED):
		_fail("Return to the rocket did not finish")
		return
	if results.size() != 1 or results[0].status != &"completed" or results[0].rescued_meeps != [&"moon_first_meep"]:
		_fail("Rescue did not return one completed Meep result")
		return
	if int(results[0].rewards.get("moon_cheese", -1)) != 0 or results[0].objective_events.size() != 4:
		_fail("Rescue result did not account for collected and shared cheese")
		return
	mode.queue_free()
	await process_frame
	var shell = (load("res://scenes/app/GameShell.tscn") as PackedScene).instantiate()
	root.add_child(shell)
	await create_timer(0.65).timeout
	shell.screen_router.open("play", {}, false)
	await create_timer(0.05).timeout
	shell.screen_router._active_screen._launch_rescue()
	await create_timer(0.05).timeout
	if shell.screen_router.active_screen_name() != "meep_rescue":
		_fail("Launcher did not open Meep Rescue")
		return
	var integrated_mode = shell.screen_router._active_screen
	if not await _wait_for_phase(integrated_mode, integrated_mode.Phase.PLAYING):
		_fail("Integrated Meep Rescue did not finish landing")
		return
	integrated_mode._exit_demo()
	await create_timer(0.05).timeout
	if shell.screen_router.active_screen_name() != "play":
		_fail("Rescue exit did not return to the launcher")
		return
	if not shell.screen_router._active_screen.get_node("Center/Panel/Content/LastRunLabel").text.contains("cancelled rescue"):
		_fail("Launcher did not show the rescue result")
		return
	shell.queue_free()
	await process_frame
	save_service.load_settings().reduced_motion = _original_reduced_motion
	print("Meep Rescue contract smoke test passed")
	quit(0)


func _wait_for_phase(mode: Control, expected: int) -> bool:
	var deadline := 4.0
	while mode.phase != expected and deadline > 0.0:
		await create_timer(0.025).timeout
		deadline -= 0.025
	return mode.phase == expected


func _fail(message: String) -> void:
	root.get_node("SaveService").load_settings().reduced_motion = _original_reduced_motion
	push_error(message)
	quit(1)
