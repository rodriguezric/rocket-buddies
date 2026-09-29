class_name AchievementsData
extends RefCounted

var unlocked_ids: Array[String] = []
var progress := {}


static func from_dict(raw: Dictionary) -> AchievementsData:
	var value := AchievementsData.new()
	for item in raw.get("unlocked_ids", []):
		if item is String and not item.is_empty() and item not in value.unlocked_ids:
			value.unlocked_ids.append(item)
	var raw_progress = raw.get("progress", {})
	if raw_progress is Dictionary:
		for key in raw_progress:
			value.progress[str(key)] = clampf(float(raw_progress[key]), 0.0, 1.0)
	return value


func to_dict() -> Dictionary:
	return {"unlocked_ids": unlocked_ids, "progress": progress}


func is_empty() -> bool:
	return unlocked_ids.is_empty() and progress.is_empty()
