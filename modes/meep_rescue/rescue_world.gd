extends Node2D

const BACKGROUND: Texture2D = preload("res://assets/art/moon/background.svg")
const BUDDY: Texture2D = preload("res://assets/art/moon/buddy.svg")
const ROCKET: Texture2D = preload("res://assets/art/moon/rocket.svg")
const CHEESE: Texture2D = preload("res://assets/art/moon/cheese.svg")
const MEEP: Texture2D = preload("res://assets/art/moon/meep.svg")
const MEEP_HAPPY: Texture2D = preload("res://assets/art/moon/meep_happy.svg")
const MEEP_SURPRISED: Texture2D = preload("res://assets/art/moon/meep_surprised.svg")
const SPEECH_BUBBLE: PackedScene = preload("res://ui/components/MeepSpeechBubble.tscn")

const INK := Color("26394f")
const CREAM := Color("fff5dc")
const TEAL := Color("73c6c7")
const GOLD := Color("f9cb65")
const CORAL := Color("ee8978")
const ROCKET_SITE := Vector2(135, 385)
const BUDDY_START := Vector2(255, 418)
const CHEESE_SITE := Vector2(410, 448)
const MEEP_SITE := Vector2(1095, 425)
const ROCK_X := 785.0
const ROCK_Y := [325.0, 420.0, 515.0]

var buddy_position := BUDDY_START
var buddy_facing := Vector2.RIGHT
var buddy_visible := true
var buddy_scale := 1.0
var rocket_position := ROCKET_SITE
var meep_position := MEEP_SITE
var meep_visible := true
var weak_rock_index := 1
var rock_revealed := false
var rock_open := false
var rock_move := 0.0
var cheese_visible := true
var cheese_toss_position := Vector2.ZERO
var cheese_toss_visible := false
var meep_rescued := false
var meep_following := false
var scan_time := 0.0
var rock_bonk_time := 0.0
var bonk_rock_index := 0
var pickup_time := 0.0
var rescue_time := 0.0
var stage: StringName = &"playing"
var _clock := 0.0
var _walk_distance := 0.0
var _walk_lift := 0.0
var _speech: Control


func _ready() -> void:
	_speech = SPEECH_BUBBLE.instantiate()
	add_child(_speech)


func reset() -> void:
	buddy_position = BUDDY_START
	buddy_facing = Vector2.RIGHT
	buddy_visible = true
	buddy_scale = 1.0
	rocket_position = ROCKET_SITE
	meep_position = MEEP_SITE
	meep_visible = true
	rock_revealed = false
	rock_open = false
	rock_move = 0.0
	cheese_visible = true
	cheese_toss_visible = false
	meep_rescued = false
	meep_following = false
	scan_time = 0.0
	rock_bonk_time = 0.0
	bonk_rock_index = 0
	pickup_time = 0.0
	rescue_time = 0.0
	stage = &"playing"
	_clock = 0.0
	_walk_distance = 0.0
	_walk_lift = 0.0
	_speech.dismiss()
	queue_redraw()


func rock_position(index: int) -> Vector2:
	return Vector2(ROCK_X, ROCK_Y[index])


func say_meep(message: String) -> void:
	_speech.position = Vector2(clampf(meep_position.x - 150.0, 20.0, 962.0), clampf(meep_position.y - 240.0, 110.0, 450.0))
	var tail_offset := meep_position.x - _speech.position.x - 150.0
	_speech.get_node("TailBorder").position.x = tail_offset
	_speech.get_node("TailFill").position.x = tail_offset
	_speech.speak(message)
	queue_redraw()


func is_meep_talking() -> bool:
	return _speech.visible


func advance_meep_dialogue() -> void:
	_speech.advance()


func close_meep_dialogue() -> void:
	if _speech.visible:
		_speech.dismiss()


func update_walk(distance: float, delta: float) -> void:
	if SaveService.is_reduced_motion():
		_walk_distance = 0.0
		_walk_lift = 0.0
	elif distance > 0.0:
		_walk_distance = fmod(_walk_distance + distance, 95.0)
		_walk_lift = (1.0 - cos(_walk_distance / 95.0 * TAU)) * 3.0
	else:
		_walk_lift = move_toward(_walk_lift, 0.0, delta * 40.0)
	queue_redraw()


func move_buddy(position_value: Vector2) -> void:
	var distance := buddy_position.distance_to(position_value)
	buddy_position = position_value
	update_walk(distance, get_process_delta_time())


func _process(delta: float) -> void:
	_clock += delta
	scan_time = maxf(0.0, scan_time - delta)
	rock_bonk_time = maxf(0.0, rock_bonk_time - delta)
	pickup_time = maxf(0.0, pickup_time - delta)
	rescue_time = maxf(0.0, rescue_time - delta)
	if meep_following and is_meep_talking() and buddy_position.distance_to(meep_position) > 180.0:
		close_meep_dialogue()
	if meep_following and stage == &"playing" and not is_meep_talking():
		var destination := buddy_position + Vector2(69.0 if buddy_facing.x < -0.2 else -69.0, 6.0)
		if buddy_position.x < ROCK_X - 65.0 and meep_position.x > ROCK_X - 65.0:
			# Guide the Meep through whichever boulder gap the player opened.
			destination = Vector2(ROCK_X + 6.0 if meep_position.x > ROCK_X + 10.0 else ROCK_X - 100.0, ROCK_Y[weak_rock_index])
		if meep_position.distance_to(destination) > 2.0:
			meep_position = meep_position.move_toward(destination, delta * 295.0)
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(BACKGROUND, Rect2(0, 0, 1280, 720), false)
	_draw_trap()
	_draw_rocket()
	if cheese_visible:
		draw_texture_rect(CHEESE, Rect2(CHEESE_SITE + Vector2(-42, -39), Vector2(84, 75)), false)
	_draw_rocks()
	if meep_visible:
		_draw_meep()
	_draw_buddy()
	if cheese_toss_visible:
		draw_texture_rect(CHEESE, Rect2(cheese_toss_position - Vector2(31, 27), Vector2(62, 55)), false)
	if scan_time > 0.0:
		_draw_scan()
	if pickup_time > 0.0:
		_draw_sparks(CHEESE_SITE, GOLD, pickup_time / 0.85)
	if rock_bonk_time > 0.0:
		_draw_sparks(rock_position(bonk_rock_index), CORAL, rock_bonk_time / 0.65)
	if rescue_time > 0.0:
		_draw_sparks(meep_position + Vector2(0, -30), GOLD, rescue_time / 2.0)
	if stage == &"launching":
		_draw_sparks(ROCKET_SITE + Vector2(0, 45), GOLD, 0.8)


func _draw_trap() -> void:
	# The three boulders cover a narrow pass to the Meep's side of the crater.
	draw_colored_polygon(PackedVector2Array([Vector2(715, 260), Vector2(857, 260), Vector2(890, 565), Vector2(720, 565)]), Color("9ebcc1"))
	draw_line(Vector2(721, 264), Vector2(855, 264), Color("bfd0d1"), 7.0)
	draw_arc(MEEP_SITE + Vector2(0, 15), 83.0, 0.0, TAU, 64, Color("9ebcc1"), 7.0)
	draw_arc(MEEP_SITE + Vector2(0, 15), 70.0, 0.0, TAU, 64, Color("bfd0d1"), 2.0)
	if not meep_rescued and not is_meep_talking():
		var bubble := 0.0 if SaveService.is_reduced_motion() else sin(_clock * 4.0) * 3.0
		_draw_text("MEEP?", MEEP_SITE + Vector2(-41, -95 + bubble), GOLD, 24)


func _draw_rocket() -> void:
	_draw_shadow(ROCKET_SITE + Vector2(0, 78), Vector2(65, 11))
	draw_set_transform(rocket_position)
	if stage == &"arriving" or stage == &"launching":
		var flame := 52.0 if SaveService.is_reduced_motion() else 52.0 + sin(_clock * 24.0) * 8.0
		draw_colored_polygon(PackedVector2Array([Vector2(-17, 55), Vector2(0, 55 + flame), Vector2(17, 55)]), GOLD)
		draw_colored_polygon(PackedVector2Array([Vector2(-9, 55), Vector2(0, 89), Vector2(9, 55)]), CREAM)
	draw_texture_rect(ROCKET, Rect2(-77, -128, 154, 212), false)
	draw_set_transform(Vector2.ZERO)


func _draw_rocks() -> void:
	for index in range(3):
		var point := rock_position(index)
		if rock_open and index == weak_rock_index:
			point += Vector2(-67.0, -132.0) * rock_move
		var wobble := 0.0
		if rock_bonk_time > 0.0 and index == bonk_rock_index and not SaveService.is_reduced_motion():
			wobble = sin(_clock * 55.0) * 4.0 * rock_bonk_time
		point.x += wobble
		_draw_shadow(rock_position(index) + Vector2(0, 39), Vector2(54, 10))
		var outline := PackedVector2Array([point + Vector2(-47, 16), point + Vector2(-33, -29), point + Vector2(1, -47), point + Vector2(39, -24), point + Vector2(53, 23), point + Vector2(15, 42), point + Vector2(-36, 37)])
		draw_colored_polygon(outline, Color("bfd0d1"))
		draw_polyline(outline + PackedVector2Array([outline[0]]), INK, 4.0, true)
		draw_circle(point + Vector2(-13, -13), 12.0, Color("d8e0df", 0.75))
		if rock_revealed and index == weak_rock_index and not rock_open:
			draw_line(point + Vector2(-5, -28), point + Vector2(10, -7), GOLD, 5.0)
			draw_line(point + Vector2(10, -7), point + Vector2(-2, 17), GOLD, 5.0)
			draw_line(point + Vector2(-2, 17), point + Vector2(8, 31), GOLD, 5.0)
			if not SaveService.is_reduced_motion():
				draw_arc(point, 58.0 + sin(_clock * 5.0) * 3.0, 0.0, TAU, 48, Color(GOLD, 0.55), 3.0)


func _draw_meep() -> void:
	var lift := 0.0
	if meep_rescued and not SaveService.is_reduced_motion():
		lift = absf(sin(_clock * 7.0)) * (11.0 if rescue_time > 0.0 else 5.0)
	elif not SaveService.is_reduced_motion():
		lift = sin(_clock * 2.5) * 2.0
	_draw_shadow(meep_position + Vector2(0, 38), Vector2(33, 8))
	var art := MEEP_HAPPY if meep_rescued else (MEEP_SURPRISED if stage == &"launching" else MEEP)
	draw_texture_rect(art, Rect2(meep_position + Vector2(-51, -68 - lift), Vector2(102, 112)), false)
	if rescue_time > 0.0 and not is_meep_talking():
		_draw_text("♥", meep_position + Vector2(-9, -84 - lift), CORAL, 26)


func _draw_buddy() -> void:
	if not buddy_visible:
		return
	_draw_shadow(buddy_position + Vector2(0, 25), Vector2(29, 8))
	draw_set_transform(buddy_position + Vector2(0, -24 - _walk_lift), 0.0, Vector2(-1.0 if buddy_facing.x < -0.15 else 1.0, 1.0) * buddy_scale)
	draw_texture_rect(BUDDY, Rect2(-48, -56, 96, 112), false)
	draw_set_transform(Vector2.ZERO)


func _draw_scan() -> void:
	var progress := 1.0 - scan_time / 0.85
	var radius := 45.0 if SaveService.is_reduced_motion() else 25.0 + progress * 720.0
	draw_arc(buddy_position, radius, 0.0, TAU, 96, Color(TEAL, scan_time * 0.8), 4.0)
	if rock_revealed and not rock_open:
		var point := rock_position(weak_rock_index)
		draw_arc(point, 68.0, 0.0, TAU, 64, Color(GOLD, scan_time), 4.0)
		_draw_text("LOOSE!", point + Vector2(-45, -72), GOLD, 22)


func _draw_sparks(center: Vector2, color: Color, opacity: float) -> void:
	for index in range(10):
		var angle := index * TAU / 10.0
		var distance := 38.0 if SaveService.is_reduced_motion() else 35.0 + (1.0 - opacity) * 80.0
		draw_circle(center + Vector2.RIGHT.rotated(angle) * distance, 5.0 * opacity, Color(color, opacity))


func _draw_shadow(at: Vector2, radius: Vector2) -> void:
	draw_set_transform(at, 0.0, radius)
	draw_circle(Vector2.ZERO, 1.0, Color(INK, 0.22))
	draw_set_transform(Vector2.ZERO)


func _draw_text(message: String, at: Vector2, color: Color, size: int) -> void:
	draw_string_outline(ThemeDB.fallback_font, at, message, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, INK)
	draw_string(ThemeDB.fallback_font, at, message, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
