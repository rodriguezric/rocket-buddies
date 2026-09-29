class_name RecordsData
extends RefCounted

var games_played := 0
var best_score := 0
var fastest_time_seconds := 0.0


static func from_dict(raw: Dictionary) -> RecordsData:
	var value := RecordsData.new()
	value.games_played = maxi(int(raw.get("games_played", 0)), 0)
	value.best_score = maxi(int(raw.get("best_score", 0)), 0)
	value.fastest_time_seconds = maxf(float(raw.get("fastest_time_seconds", 0.0)), 0.0)
	return value


func to_dict() -> Dictionary:
	return {
		"games_played": games_played,
		"best_score": best_score,
		"fastest_time_seconds": fastest_time_seconds,
	}


func is_empty() -> bool:
	return games_played == 0 and best_score == 0 and fastest_time_seconds == 0.0
