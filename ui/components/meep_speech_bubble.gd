extends Control

signal closed

const LETTERS_PER_SECOND := 32.0
var _letters := 0.0


func speak(message: String) -> void:
	%Dialogue.text = message
	_letters = 0.0
	%Dialogue.visible_characters = -1 if SaveService.is_reduced_motion() else 0
	show()
	_update_hint()


func _process(delta: float) -> void:
	if not visible or not is_revealing():
		return
	if SaveService.is_reduced_motion():
		%Dialogue.visible_characters = -1
	else:
		_letters += delta * LETTERS_PER_SECOND
		%Dialogue.visible_characters = mini(int(_letters), %Dialogue.get_total_character_count())
	_update_hint()


func is_revealing() -> bool:
	return %Dialogue.visible_characters >= 0 and %Dialogue.visible_characters < %Dialogue.get_total_character_count()


func advance() -> void:
	if is_revealing():
		%Dialogue.visible_characters = -1
		_update_hint()
	else:
		dismiss()


func dismiss() -> void:
	hide()
	closed.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		advance()
		accept_event()


func _update_hint() -> void:
	%Hint.text = "E / A or click • Show all" if is_revealing() else "E / A or click • Close"
