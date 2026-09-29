extends Control

signal back_requested

var _loading := true
var _settings: SettingsData


func _ready() -> void:
	%MasterSlider.value_changed.connect(func(value: float) -> void: _set_volume("master", value))
	%MusicSlider.value_changed.connect(func(value: float) -> void: _set_volume("music", value))
	%SfxSlider.value_changed.connect(func(value: float) -> void: _set_volume("sfx", value))
	%ReducedMotion.toggled.connect(_on_reduced_motion_toggled)
	%ResetButton.pressed.connect(_on_reset_pressed)
	%ClearDataButton.pressed.connect(func() -> void: %ClearConfirmation.popup_centered())
	%ClearConfirmation.confirmed.connect(_on_clear_confirmed)
	%BackButton.pressed.connect(func() -> void: back_requested.emit())
	%Bindings.text = InputProfile.binding_summary()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not %ClearConfirmation.visible:
		back_requested.emit()
		get_viewport().set_input_as_handled()


func get_initial_focus() -> Control:
	return %MasterSlider


func _refresh() -> void:
	_loading = true
	_settings = SaveService.load_settings()
	%MasterSlider.value = _settings.master_volume * 100.0
	%MusicSlider.value = _settings.music_volume * 100.0
	%SfxSlider.value = _settings.sfx_volume * 100.0
	%ReducedMotion.button_pressed = _settings.reduced_motion
	%Status.text = "Settings apply immediately and are saved locally."
	_loading = false


func _set_volume(channel: String, value: float) -> void:
	if _loading:
		return
	match channel:
		"master": _settings.master_volume = value / 100.0
		"music": _settings.music_volume = value / 100.0
		"sfx": _settings.sfx_volume = value / 100.0
	SaveService.save_settings(_settings)
	%Status.text = "%s volume: %d%%" % [channel.capitalize(), int(value)]


func _on_reduced_motion_toggled(enabled: bool) -> void:
	if _loading:
		return
	_settings.reduced_motion = enabled
	SaveService.save_settings(_settings)
	%Status.text = "Reduced motion %s." % ("enabled" if enabled else "disabled")


func _on_reset_pressed() -> void:
	SaveService.reset_settings()
	_refresh()
	%Status.text = "Settings and controls reset to defaults."


func _on_clear_confirmed() -> void:
	SaveService.clear_all_data()
	_refresh()
	%Status.text = "All local settings, records, and achievements cleared."
