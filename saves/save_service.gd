extends Node

signal settings_changed
signal data_cleared(scope: String)
signal save_failed(message: String)

const PROFILE_PATH := "user://base_screen_profile.json"
const BACKUP_PATH := "user://base_screen_profile.json.bak"
const TEMP_PATH := "user://base_screen_profile.json.tmp"
const PROFILE_VERSION := 1

var _settings := SettingsData.new()
var _records := RecordsData.new()
var _achievements := AchievementsData.new()


func _ready() -> void:
	_load_profile()
	apply_settings()


func load_settings() -> SettingsData:
	return _settings


func save_settings(value: SettingsData) -> bool:
	_settings = value
	apply_settings()
	var saved := _save_profile()
	settings_changed.emit()
	return saved


func load_records() -> RecordsData:
	return _records


func save_records(value: RecordsData) -> bool:
	_records = value
	return _save_profile()


func load_achievements() -> AchievementsData:
	return _achievements


func save_achievements(value: AchievementsData) -> bool:
	_achievements = value
	return _save_profile()


func reset_settings() -> bool:
	_settings = SettingsData.new()
	InputProfile.reset_to_project_defaults()
	apply_settings()
	var saved := _save_profile()
	settings_changed.emit()
	data_cleared.emit("settings")
	return saved


func clear_records() -> bool:
	_records = RecordsData.new()
	var saved := _save_profile()
	data_cleared.emit("records")
	return saved


func clear_achievements() -> bool:
	_achievements = AchievementsData.new()
	var saved := _save_profile()
	data_cleared.emit("achievements")
	return saved


func clear_all_data() -> bool:
	_settings = SettingsData.new()
	_records = RecordsData.new()
	_achievements = AchievementsData.new()
	InputProfile.reset_to_project_defaults()
	apply_settings()
	var saved := _save_profile()
	settings_changed.emit()
	data_cleared.emit("all")
	return saved


func is_reduced_motion() -> bool:
	return _settings.reduced_motion


func apply_settings() -> void:
	_set_bus_volume(&"Master", _settings.master_volume)
	_set_bus_volume(&"Music", _settings.music_volume)
	_set_bus_volume(&"SFX", _settings.sfx_volume)


func _set_bus_volume(bus_name: StringName, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var linear := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, -80.0 if linear <= 0.0 else linear_to_db(linear))


func _load_profile() -> void:
	var raw := _read_profile(PROFILE_PATH)
	if raw.is_empty():
		raw = _read_profile(BACKUP_PATH)
	_settings = SettingsData.from_dict(raw.get("settings", {}))
	_records = RecordsData.from_dict(raw.get("records", {}))
	_achievements = AchievementsData.from_dict(raw.get("achievements", {}))


func _read_profile(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary:
		return {}
	return parsed


func _save_profile() -> bool:
	var payload := {
		"version": PROFILE_VERSION,
		"settings": _settings.to_dict(),
		"records": _records.to_dict(),
		"achievements": _achievements.to_dict(),
	}
	var temporary := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if temporary == null:
		return _report_save_failure("Could not open temporary save file.")
	temporary.store_string(JSON.stringify(payload, "  "))
	temporary.close()

	var absolute_profile := ProjectSettings.globalize_path(PROFILE_PATH)
	var absolute_backup := ProjectSettings.globalize_path(BACKUP_PATH)
	var absolute_temp := ProjectSettings.globalize_path(TEMP_PATH)
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(absolute_backup)
	if FileAccess.file_exists(PROFILE_PATH):
		var backup_error := DirAccess.rename_absolute(absolute_profile, absolute_backup)
		if backup_error != OK:
			return _report_save_failure("Could not preserve the previous save.")
	var commit_error := DirAccess.rename_absolute(absolute_temp, absolute_profile)
	if commit_error != OK:
		if FileAccess.file_exists(BACKUP_PATH):
			DirAccess.rename_absolute(absolute_backup, absolute_profile)
		return _report_save_failure("Could not finalize the new save.")
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(absolute_backup)
	return true


func _report_save_failure(message: String) -> bool:
	push_error(message)
	save_failed.emit(message)
	return false
