extends SceneTree

var _original_reduced_motion := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var save_service = root.get_node("SaveService")
	_original_reduced_motion = save_service.load_settings().reduced_motion
	save_service.load_settings().reduced_motion = true
	var mode = (load("res://modes/cheese_hunt/MoonCheeseHunt.tscn") as PackedScene).instantiate()
	root.add_child(mode)
	await process_frame
	var context := ModeContext.new()
	context.mode_id = &"cheese_hunt"
	context.destination_id = &"moon"
	context.parameters = {"target_count": 2, "seed": 42}
	mode.present({"mode_context": context})
	if not await _wait_for_phase(mode, mode.Phase.PLAYING):
		_fail("Cheese Hunt arrival did not enable play")
		return
	var results: Array[ModeResult] = []
	mode.mode_completed.connect(func(result: ModeResult) -> void: results.append(result))
	mode._select(mode.deposits[0])
	mode._scan()
	if mode.scan_charge != 2 or not mode.get_node("HUD/StatusPanel/StatusColumn/ClueLabel").text.contains("JACKPOT"):
		_fail("Scanning a deposit did not reveal a clear dig clue")
		return
	mode._dig()
	var empty_cell := Vector2i(-1, -1)
	for row in range(mode.world.GRID_ROWS):
		for column in range(mode.world.GRID_COLUMNS):
			var candidate := Vector2i(column, row)
			if not mode.deposits.has(candidate):
				empty_cell = candidate
				break
		if empty_cell.x >= 0:
			break
	mode._select(empty_cell)
	mode._dig()
	if mode.cheese_collected != 1 or mode.digs_used != 2 or not mode.world.empty_cells.has(empty_cell):
		_fail("Digging an empty patch incorrectly awarded cheese")
		return
	mode.scan_charge = 0
	mode._recharge_time = 0.0
	mode._process(mode.SCAN_RECHARGE_SECONDS)
	if mode.scan_charge != 1:
		_fail("Scanner charges did not replenish")
		return
	mode._select(mode.deposits[1])
	mode._dig()
	if not await _wait_for_phase(mode, mode.Phase.FINISHED):
		_fail("Finding the final deposit did not finish the hunt")
		return
	if results.size() != 1 or results[0].status != &"completed" or int(results[0].rewards.get("moon_cheese", 0)) != 2:
		_fail("Cheese Hunt returned the wrong completed result")
		return
	if results[0].objective_events.size() != 2 or results[0].metadata.get("destination_id") != &"moon":
		_fail("Cheese Hunt result lost its objective or destination")
		return
	mode.queue_free()
	await process_frame
	var shell = (load("res://scenes/app/GameShell.tscn") as PackedScene).instantiate()
	root.add_child(shell)
	await create_timer(0.65).timeout
	shell.screen_router.open("play", {}, false)
	await create_timer(0.05).timeout
	shell.screen_router._active_screen._launch_hunt()
	await create_timer(0.05).timeout
	if shell.screen_router.active_screen_name() != "moon_cheese_hunt":
		_fail("Launcher did not open Moon Cheese Hunt")
		return
	var integrated_mode = shell.screen_router._active_screen
	if not await _wait_for_phase(integrated_mode, integrated_mode.Phase.PLAYING):
		_fail("Integrated Cheese Hunt did not start")
		return
	integrated_mode._exit_demo()
	await create_timer(0.05).timeout
	if shell.screen_router.active_screen_name() != "play":
		_fail("Cheese Hunt exit did not return to the launcher")
		return
	if not shell.screen_router._active_screen.get_node("Center/Panel/Content/LastRunLabel").text.contains("cancelled hunt"):
		_fail("Launcher did not display the hunt result")
		return
	shell.queue_free()
	await process_frame
	save_service.load_settings().reduced_motion = _original_reduced_motion
	print("Moon Cheese Hunt contract smoke test passed")
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
