extends Control

signal mode_completed(result: ModeResult)

enum Phase { ARRIVING, PLAYING, CELEBRATING, FINISHED }

const MAX_SCAN_CHARGE := 3
const SCAN_RECHARGE_SECONDS := 2.5

@onready var world: Node2D = $World

var mode_context: ModeContext
var phase := Phase.ARRIVING
var deposits: Array[Vector2i] = []
var scan_clues: Dictionary = {}
var target_count := 3
var cheese_collected := 0
var scans_used := 0
var digs_used := 0
var scan_charge := MAX_SCAN_CHARGE
var _recharge_time := 0.0
var _message_time := 0.0
var _sequence_tween: Tween
var _rng := RandomNumberGenerator.new()
var _run_number := 0


func _ready() -> void:
	%RestartButton.pressed.connect(_restart)
	%ExitButton.pressed.connect(_exit_demo)
	resized.connect(_resize_world)
	_resize_world()
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
	context.mode_id = &"cheese_hunt"
	context.destination_id = &"moon"
	return context


func _resize_world() -> void:
	if world != null:
		world.scale = Vector2(size.x / 1280.0, size.y / 720.0)


func _process(delta: float) -> void:
	if phase != Phase.PLAYING:
		return
	if scan_charge < MAX_SCAN_CHARGE:
		_recharge_time += delta
		if _recharge_time >= SCAN_RECHARGE_SECONDS:
			_recharge_time -= SCAN_RECHARGE_SECONDS
			scan_charge += 1
			_update_hud()
	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0:
			%FeedbackLabel.text = "Scan a patch, follow the clue, then dig where the signal is strongest."


func _unhandled_input(event: InputEvent) -> void:
	if phase != Phase.PLAYING:
		return
	if event.is_action_pressed("move_left"):
		_move_selection(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"):
		_move_selection(Vector2i.RIGHT)
	elif event.is_action_pressed("move_up"):
		_move_selection(Vector2i.UP)
	elif event.is_action_pressed("move_down"):
		_move_selection(Vector2i.DOWN)
	elif event.is_action_pressed("scan"):
		_scan()
	elif event.is_action_pressed("interact"):
		_dig()
	elif event.is_action_pressed("restart_demo"):
		_restart()
	elif event.is_action_pressed("ui_cancel"):
		_exit_demo()
	else:
		return
	get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if phase != Phase.PLAYING or event is not InputEventMouseButton:
		return
	var click := event as InputEventMouseButton
	if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var local_position := Vector2(click.position.x / world.scale.x, click.position.y / world.scale.y)
	var cell: Vector2i = world.cell_at(local_position)
	if cell.x < 0:
		return
	if cell == world.selected:
		_dig()
	else:
		_select(cell)
	get_viewport().set_input_as_handled()


func _move_selection(direction: Vector2i) -> void:
	var next_cell: Vector2i = world.selected + direction
	if next_cell.x < 0 or next_cell.x >= world.GRID_COLUMNS or next_cell.y < 0 or next_cell.y >= world.GRID_ROWS:
		return
	_select(next_cell)


func _select(cell: Vector2i) -> void:
	world.selected = cell
	world.queue_redraw()
	if world.found_cells.has(cell):
		%ClueLabel.text = "Cheese found here!"
	elif world.empty_cells.has(cell):
		%ClueLabel.text = "This patch is empty."
	elif scan_clues.has(cell):
		%ClueLabel.text = scan_clues[cell]
	else:
		%ClueLabel.text = "Press Q / X to scan this patch."


func _scan() -> void:
	if world.found_cells.has(world.selected) or world.empty_cells.has(world.selected):
		_show_message("That patch has already been dug. Try another one.")
		return
	if scan_charge <= 0:
		_show_message("Scanner charging... one pulse will be ready soon.")
		return
	scan_charge -= 1
	scans_used += 1
	var closest := Vector2i.ZERO
	var distance := 99
	for deposit in deposits:
		if world.found_cells.has(deposit):
			continue
		var offset: Vector2i = deposit - world.selected
		var steps := absi(offset.x) + absi(offset.y)
		if steps < distance:
			distance = steps
			closest = offset
	var heat := 3 if distance == 0 else (2 if distance == 1 else (1 if distance == 2 else 0))
	world.play_scan(heat)
	var clue := "JACKPOT! Dig right here!" if distance == 0 else "%s • Signal %s" % ["HOT" if distance == 1 else ("WARM" if distance == 2 else "FAINT"), _direction_to(closest)]
	scan_clues[world.selected] = clue
	%ClueLabel.text = clue
	_show_message("Scanner: " + clue, 3.5)
	_update_hud()


func _direction_to(offset: Vector2i) -> String:
	var vertical := "NORTH" if offset.y < 0 else ("SOUTH" if offset.y > 0 else "")
	var horizontal := "WEST" if offset.x < 0 else ("EAST" if offset.x > 0 else "")
	return vertical + ("-" if not vertical.is_empty() and not horizontal.is_empty() else "") + horizontal


func _dig() -> void:
	if world.found_cells.has(world.selected):
		_show_message("Already in your cheese bag!")
		return
	if world.empty_cells.has(world.selected):
		_show_message("Just moon dust here. Pick another patch.")
		return
	digs_used += 1
	if deposits.has(world.selected):
		world.found_cells.append(world.selected)
		cheese_collected += 1
		world.play_dig(true)
		world.scan_marks.erase(world.selected)
		scan_clues.erase(world.selected)
		_show_message("Moon Cheese! A deliciously mysterious discovery.", 3.0)
		%ClueLabel.text = "FOUND! Choose another patch."
		if cheese_collected >= target_count:
			_complete()
	else:
		world.empty_cells.append(world.selected)
		world.play_dig(false)
		_show_message("Poof! Just moon dust. The next dig might be the one.", 3.0)
		%ClueLabel.text = "Empty patch. Scan somewhere nearby."
	_update_hud()


func _show_message(message: String, seconds := 2.7) -> void:
	%FeedbackLabel.text = message
	_message_time = seconds


func _update_hud() -> void:
	%ObjectiveLabel.text = "MOON CHEESE  %d / %d" % [cheese_collected, target_count]
	%ScannerLabel.text = "SCANNER  %d / %d" % [scan_charge, MAX_SCAN_CHARGE]
	%ScanBar.value = scan_charge
	%ScoreLabel.text = "SCANS  %d     DIGS  %d" % [scans_used, digs_used]


func _make_result(status: StringName) -> ModeResult:
	var result := ModeResult.new()
	result.status = status
	result.rewards = {"moon_cheese": cheese_collected}
	if cheese_collected > 0:
		result.objective_events.append({"type": &"item_collected", "id": &"moon_cheese", "amount": cheese_collected})
	if status == &"completed":
		result.objective_events.append({"type": &"activity_completed", "id": &"moon_cheese_hunt"})
	result.metadata = {"mode_id": mode_context.mode_id, "destination_id": mode_context.destination_id, "scans_used": scans_used, "digs_used": digs_used}
	return result


func _complete() -> void:
	phase = Phase.CELEBRATING
	world.celebrating = true
	%PromptLabel.text = "CHEESE STASH COMPLETE!"
	%FeedbackLabel.text = "Three cheers for the galaxy's finest cheese hunter!"
	%RestartButton.disabled = true
	%ExitButton.disabled = true
	var reduced := SaveService.is_reduced_motion()
	_sequence_tween = create_tween()
	_sequence_tween.tween_interval(0.4 if reduced else 1.6)
	_sequence_tween.tween_property(%Fade, "color:a", 1.0, 0.01 if reduced else 0.5)
	_sequence_tween.tween_callback(func() -> void: _emit_result(_make_result(&"completed")))


func _exit_demo() -> void:
	if phase == Phase.PLAYING:
		_emit_result(_make_result(&"cancelled"))


func _emit_result(result: ModeResult) -> void:
	if phase == Phase.FINISHED:
		return
	phase = Phase.FINISHED
	if mode_completed.get_connections().is_empty():
		print("Cheese Hunt result: ", result.status, " ", result.rewards, " ", result.metadata)
		get_tree().quit()
	else:
		mode_completed.emit(result)


func _restart() -> void:
	if _sequence_tween != null:
		_sequence_tween.kill()
	_run_number += 1
	phase = Phase.ARRIVING
	world.reset()
	deposits.clear()
	scan_clues.clear()
	target_count = clampi(int(mode_context.parameters.get("target_count", 3)), 1, 5)
	var seed_value := int(mode_context.parameters.get("seed", 0))
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value + _run_number - 1
	while deposits.size() < target_count:
		var candidate := Vector2i(_rng.randi_range(0, world.GRID_COLUMNS - 1), _rng.randi_range(0, world.GRID_ROWS - 1))
		if not deposits.has(candidate):
			deposits.append(candidate)
	cheese_collected = 0
	scans_used = 0
	digs_used = 0
	scan_charge = MAX_SCAN_CHARGE
	_recharge_time = 0.0
	_message_time = 0.0
	%Fade.color.a = 0.0
	%PromptLabel.text = "ARRIVING AT THE DIG SITE..."
	%ClueLabel.text = "Choose a patch and scan for a clue."
	%FeedbackLabel.text = "Moon Cheese is hiding just below the surface!"
	%RestartButton.disabled = true
	%ExitButton.disabled = true
	_update_hud()
	var reduced := SaveService.is_reduced_motion()
	_sequence_tween = create_tween()
	_sequence_tween.tween_property(world, "buddy_position", Vector2(150, 410), 0.01 if reduced else 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_sequence_tween.tween_callback(func() -> void:
		phase = Phase.PLAYING
		%PromptLabel.text = "WASD / STICK  •  PICK PATCH     Q / X  •  SCAN     E / A  •  DIG"
		%RestartButton.disabled = false
		%ExitButton.disabled = false
	)
