extends Control

const SCREEN_REGISTRY := {
    "opening": preload("res://scenes/opening/Opening.tscn"),
    "title": preload("res://scenes/title/TitleScreen.tscn"),
    "play": preload("res://game/PlayScreen.tscn"),
    "moon_exploration": preload("res://modes/exploration/MoonExploration.tscn"),
    "rocket_flight": preload("res://modes/flight/RocketFlight.tscn"),
    "moon_cheese_hunt": preload("res://modes/cheese_hunt/MoonCheeseHunt.tscn"),
    "meep_rescue": preload("res://modes/meep_rescue/MeepRescue.tscn"),
    "settings": preload("res://scenes/settings/SettingsScreen.tscn"),
    "records": preload("res://scenes/records/RecordsScreen.tscn"),
    "achievements": preload("res://scenes/achievements/AchievementsScreen.tscn"),
}

@onready var screen_router: ScreenRouter = %ScreenRouter


func _ready() -> void:
    screen_router.configure(%ScreenLayer, %TransitionLayer, SCREEN_REGISTRY)
    screen_router.quit_requested.connect(_on_quit_requested)
    screen_router.mode_completed.connect(_on_mode_completed)
    screen_router.open("opening", {}, false)


func _on_quit_requested() -> void:
    get_tree().quit()


func _on_mode_completed(result: ModeResult) -> void:
    screen_router.clear_history()
    screen_router.open("play", {"last_result": result}, false)
