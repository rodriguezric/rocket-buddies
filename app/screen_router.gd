class_name ScreenRouter
extends Node

signal screen_changed(screen_name: String)
signal quit_requested
signal mode_completed(result: ModeResult)

var _screen_layer: Control
var _transition_layer: Control
var _registry := {}
var _history: Array[Dictionary] = []
var _active_screen: Control
var _active_name := ""
var _active_context := {}
var _transitioning := false
var _pending_request := {}


func configure(screen_layer: Control, transition_layer: Control, registry: Dictionary) -> void:
	_screen_layer = screen_layer
	_transition_layer = transition_layer
	_registry = registry.duplicate()


func open(screen_name: String, context: Dictionary = {}, remember := true) -> void:
	if not _registry.has(screen_name):
		push_error("Unknown screen: %s" % screen_name)
		return
	var request := {"name": screen_name, "context": context.duplicate(true), "remember": remember}
	if _transitioning:
		_pending_request = request
		return
	_navigate(request)


func back() -> void:
	if _transitioning:
		_pending_request = {"back": true}
		return
	if _history.is_empty():
		open("title", {}, false)
		return
	var destination: Dictionary = _history.pop_back()
	destination["remember"] = false
	_navigate(destination)


func active_screen_name() -> String:
	return _active_name


func clear_history() -> void:
	_history.clear()


func _navigate(request: Dictionary) -> void:
	_transitioning = true
	_set_input_enabled(false)
	if bool(request.get("remember", true)) and not _active_name.is_empty():
		_history.append({
			"name": _active_name,
			"context": _active_context.duplicate(true),
			"focus_path": _focused_path(),
		})

	var reduced_motion := SaveService.is_reduced_motion()
	if is_instance_valid(_active_screen):
		if not reduced_motion:
			var fade_out := create_tween()
			fade_out.tween_property(_active_screen, "modulate:a", 0.0, 0.14)
			await fade_out.finished
		_active_screen.queue_free()
		_active_screen = null

	var screen_name := str(request.get("name", "title"))
	var context: Dictionary = request.get("context", {})
	var instance = (_registry[screen_name] as PackedScene).instantiate()
	if instance is not Control:
		push_error("Screen '%s' must have a Control root." % screen_name)
		_finish_transition()
		return

	_active_screen = instance
	_active_name = screen_name
	_active_context = context.duplicate(true)
	_screen_layer.add_child(_active_screen)
	_active_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_connect_screen_intents(_active_screen)
	if _active_screen.has_method("present"):
		_active_screen.present(context)
	if not reduced_motion:
		_active_screen.modulate.a = 0.0
		var fade_in := create_tween()
		fade_in.tween_property(_active_screen, "modulate:a", 1.0, 0.18)
		await fade_in.finished
	_restore_focus(str(request.get("focus_path", "")))
	screen_changed.emit(screen_name)
	_finish_transition()


func _finish_transition() -> void:
	_transitioning = false
	_set_input_enabled(true)
	if _pending_request.is_empty():
		return
	var next_request := _pending_request
	_pending_request = {}
	if bool(next_request.get("back", false)):
		back.call_deferred()
	else:
		_navigate.call_deferred(next_request)


func _connect_screen_intents(screen: Control) -> void:
	if screen.has_signal("navigation_requested"):
		screen.connect("navigation_requested", Callable(self, "open"))
	if screen.has_signal("back_requested"):
		screen.connect("back_requested", Callable(self, "back"))
	if screen.has_signal("quit_requested"):
		screen.connect("quit_requested", func() -> void: quit_requested.emit())
	if screen.has_signal("mode_completed"):
		screen.connect("mode_completed", func(result: ModeResult) -> void: mode_completed.emit(result))


func _set_input_enabled(enabled: bool) -> void:
	if is_instance_valid(_active_screen):
		_active_screen.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
		_active_screen.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	_transition_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE if enabled else Control.MOUSE_FILTER_STOP


func _focused_path() -> String:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or not _active_screen.is_ancestor_of(focused):
		return ""
	return str(_active_screen.get_path_to(focused))


func _restore_focus(saved_path: String) -> void:
	var target: Control
	if not saved_path.is_empty():
		target = _active_screen.get_node_or_null(saved_path) as Control
	if target == null and _active_screen.has_method("get_initial_focus"):
		target = _active_screen.get_initial_focus()
	if target != null and target.is_visible_in_tree() and target.focus_mode != Control.FOCUS_NONE:
		target.grab_focus.call_deferred()
