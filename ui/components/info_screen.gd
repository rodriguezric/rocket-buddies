extends Control

signal back_requested

@export var heading := "INFORMATION"
@export_multiline var empty_message := "Nothing to show yet."
@export_enum("records", "achievements") var data_kind := "records"


func _ready() -> void:
	%Heading.text = heading
	%EmptyMessage.text = empty_message
	%BackButton.pressed.connect(func() -> void: back_requested.emit())
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()


func get_initial_focus() -> Control:
	return %BackButton


func _refresh() -> void:
	var is_empty := true
	if data_kind == "records":
		is_empty = SaveService.load_records().is_empty()
	else:
		is_empty = SaveService.load_achievements().is_empty()
	%EmptyMessage.visible = is_empty
	%PopulatedMessage.visible = not is_empty
