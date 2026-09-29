extends Control

signal navigation_requested(screen_name: String, context: Dictionary, remember: bool)

var _finished := false
var _tween: Tween


func _ready() -> void:
	_play_opening.call_deferred()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		finish_opening()
	elif event is InputEventMouseButton and event.pressed:
		finish_opening()


func _play_opening() -> void:
	if SaveService.is_reduced_motion():
		await get_tree().create_timer(0.12).timeout
	else:
		%Logo.modulate.a = 0.0
		%Logo.position.y += 18.0
		_tween = create_tween().set_parallel(true)
		_tween.tween_property(%Logo, "modulate:a", 1.0, 0.7)
		_tween.tween_property(%Logo, "position:y", %Logo.position.y - 18.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await _tween.finished
		await get_tree().create_timer(0.45).timeout
	finish_opening()


func finish_opening() -> void:
	if _finished:
		return
	_finished = true
	if _tween != null and _tween.is_valid():
		_tween.kill()
	%Logo.modulate.a = 1.0
	navigation_requested.emit("title", {}, false)


func get_initial_focus() -> Control:
	return null
