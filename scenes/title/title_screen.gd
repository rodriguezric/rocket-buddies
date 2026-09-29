extends Control

signal navigation_requested(screen_name: String, context: Dictionary, remember: bool)
signal quit_requested


func _ready() -> void:
	%PlayButton.pressed.connect(func() -> void: navigation_requested.emit("play", {}, true))
	%SettingsButton.pressed.connect(func() -> void: navigation_requested.emit("settings", {}, true))
	%RecordsButton.pressed.connect(func() -> void: navigation_requested.emit("records", {}, true))
	%AchievementsButton.pressed.connect(func() -> void: navigation_requested.emit("achievements", {}, true))
	%QuitButton.pressed.connect(func() -> void: quit_requested.emit())


func get_initial_focus() -> Control:
	return %PlayButton
