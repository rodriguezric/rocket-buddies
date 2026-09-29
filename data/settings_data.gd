class_name SettingsData
extends RefCounted

var master_volume := 1.0
var music_volume := 0.8
var sfx_volume := 0.9
var reduced_motion := false


static func from_dict(raw: Dictionary) -> SettingsData:
	var value := SettingsData.new()
	value.master_volume = clampf(float(raw.get("master_volume", value.master_volume)), 0.0, 1.0)
	value.music_volume = clampf(float(raw.get("music_volume", value.music_volume)), 0.0, 1.0)
	value.sfx_volume = clampf(float(raw.get("sfx_volume", value.sfx_volume)), 0.0, 1.0)
	value.reduced_motion = bool(raw.get("reduced_motion", value.reduced_motion))
	return value


func to_dict() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"reduced_motion": reduced_motion,
	}
