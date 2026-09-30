extends Node2D

const BACKGROUND: Texture2D = preload("res://assets/art/moon/background.svg")
const BUDDY: Texture2D = preload("res://assets/art/moon/buddy.svg")
const ROCKET_ART: Texture2D = preload("res://assets/art/moon/rocket.svg")
const CHEESE_ART: Texture2D = preload("res://assets/art/moon/cheese.svg")
const CRATER_ART: Texture2D = preload("res://assets/art/moon/crater.svg")
const MEEP_ART: Texture2D = preload("res://assets/art/moon/meep.svg")
const HAPPY_MEEP_ART: Texture2D = preload("res://assets/art/moon/meep_happy.svg")
const SPEECH_BUBBLE: PackedScene = preload("res://ui/components/MeepSpeechBubble.tscn")

const ROCKET := Vector2(156, 382)
const CHEESE := Vector2(735, 470)
const DISCOVERY := Vector2(1000, 265)
const MEEP := Vector2(1110, 445)
const WALK_BOUNCE_HEIGHT := 5.0
const WALK_BOUNCE_DISTANCE := 100.0
const PICKUP_DURATION := 0.9
const SCAN_RANGE := 300.0
const SCAN_WAVE_DURATION := 0.75
const SCAN_EFFECT_DURATION := 1.8

var buddy_position := Vector2(270, 405)
var buddy_facing := Vector2.RIGHT
var cheese_collected := false
var discovery_found := false
var meep_rescued := false
var meep_position := MEEP
var _meep_destination := MEEP
var _meep_wait := 3.0
var _meep_rng := RandomNumberGenerator.new()
var _speech: Control
var _meep_celebration := 0.0
var _scan_time := 0.0
var _scan_origin := Vector2.ZERO
var _walk_distance := 0.0
var _walk_lift := 0.0
var _pickup_time := 0.0


func _ready() -> void:
	_meep_rng.randomize()
	_speech = SPEECH_BUBBLE.instantiate()
	add_child(_speech)
	_speech.closed.connect(func() -> void: _meep_wait = 3.0)


func is_meep_talking() -> bool:
	return _speech != null and _speech.visible


func say_meep(message: String) -> void:
	_meep_destination = meep_position
	_speech.position = Vector2(clampf(meep_position.x - 150.0, 20.0, 960.0), meep_position.y - 234.0)
	var tail_offset := meep_position.x - _speech.position.x - 150.0
	_speech.get_node("TailBorder").position.x = tail_offset
	_speech.get_node("TailFill").position.x = tail_offset
	_speech.speak(message)
	queue_redraw()


func advance_meep_dialogue() -> void:
	_speech.advance()


func close_meep_dialogue() -> void:
	_speech.dismiss()


func rescue_meep() -> void:
	meep_rescued = true
	_meep_celebration = 2.0
	queue_redraw()


func reset_meep() -> void:
	meep_rescued = false
	meep_position = MEEP
	_meep_destination = MEEP
	_meep_wait = 3.0
	close_meep_dialogue()
	_meep_celebration = 0.0
	queue_redraw()


func play_scan() -> void:
	_scan_origin = buddy_position
	_scan_time = SCAN_EFFECT_DURATION
	queue_redraw()


func reset_scan_effect() -> void:
	_scan_time = 0.0
	queue_redraw()


func play_cheese_pickup() -> void:
	_pickup_time = PICKUP_DURATION
	queue_redraw()


func reset_pickup_effect() -> void:
	_pickup_time = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_update_meep_walk(delta)
	if _meep_celebration > 0.0 and not is_meep_talking():
		_meep_celebration = maxf(0.0, _meep_celebration - delta)
		queue_redraw()
	if _scan_time > 0.0:
		_scan_time = maxf(0.0, _scan_time - delta)
		queue_redraw()
	if _pickup_time > 0.0:
		_pickup_time = maxf(0.0, _pickup_time - delta)
		queue_redraw()


func _update_meep_walk(delta: float) -> void:
	if is_meep_talking() or _meep_celebration > 0.0:
		return
	# Stay near the Buddy when approached so interaction remains easy.
	if buddy_position.distance_to(meep_position) < 115.0:
		_meep_destination = meep_position
		return
	if meep_position.distance_to(_meep_destination) > 1.0:
		meep_position = meep_position.move_toward(_meep_destination, delta * 32.0)
		queue_redraw()
	else:
		_meep_wait -= delta
		if _meep_wait <= 0.0:
			_meep_destination = Vector2(_meep_rng.randf_range(1015.0, 1195.0), _meep_rng.randf_range(410.0, 490.0))
			_meep_wait = _meep_rng.randf_range(3.0, 6.0)


func update_walk_animation(distance: float, delta: float, reduced_motion: bool) -> void:
	var previous_lift := _walk_lift
	if reduced_motion:
		_walk_distance = 0.0
		_walk_lift = 0.0
	elif distance > 0.0:
		_walk_distance = fmod(_walk_distance + distance, WALK_BOUNCE_DISTANCE)
		_walk_lift = (1.0 - cos(_walk_distance / WALK_BOUNCE_DISTANCE * TAU)) * WALK_BOUNCE_HEIGHT * 0.5
	else:
		_walk_lift = move_toward(_walk_lift, 0.0, delta * 40.0)
		if is_zero_approx(_walk_lift):
			_walk_distance = 0.0
	if not is_equal_approx(previous_lift, _walk_lift):
		queue_redraw()


func reset_walk_animation() -> void:
	_walk_distance = 0.0
	_walk_lift = 0.0
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(BACKGROUND, Rect2(0, 0, 1280, 720), false)
	draw_texture_rect(ROCKET_ART, Rect2(ROCKET + Vector2(-80, -130), Vector2(160, 220)), false)
	draw_texture_rect(CRATER_ART, Rect2(DISCOVERY + Vector2(-65, -50), Vector2(130, 100)), false)
	if not cheese_collected:
		draw_texture_rect(CHEESE_ART, Rect2(CHEESE + Vector2(-45, -40), Vector2(90, 80)), false)
	_draw_meep()
	if discovery_found:
		draw_circle(DISCOVERY + Vector2(49, -37), 13.0, Color("73c6c7"))
		draw_line(DISCOVERY + Vector2(43, -37), DISCOVERY + Vector2(48, -31), Color("26394f"), 3.0)
		draw_line(DISCOVERY + Vector2(48, -31), DISCOVERY + Vector2(56, -43), Color("26394f"), 3.0)
	if _scan_time > 0.0:
		_draw_scan_effect()
	_draw_oval_shadow(buddy_position + Vector2(0, 22), Vector2(28 - _walk_lift * 0.5, 8), Color("9ebcc1"))
	draw_set_transform(buddy_position + Vector2(0, -24 - _walk_lift), 0.0, Vector2(-1.0 if buddy_facing.x < -0.15 else 1.0, 1.0))
	draw_texture_rect(BUDDY, Rect2(-48, -56, 96, 112), false)
	draw_set_transform(Vector2.ZERO)
	if _pickup_time > 0.0:
		_draw_pickup_effect()


func _draw_scan_effect() -> void:
	var elapsed := SCAN_EFFECT_DURATION - _scan_time
	var reduced_motion := SaveService.is_reduced_motion()
	var reached_radius := SCAN_RANGE if reduced_motion else minf(elapsed / SCAN_WAVE_DURATION, 1.0) * SCAN_RANGE
	var highlight_alpha := minf(_scan_time / 0.4, 1.0)
	if reduced_motion:
		if elapsed < SCAN_WAVE_DURATION:
			draw_arc(_scan_origin, 45.0, 0.0, TAU, 64, Color("73c6c7", 0.6), 3.0, true)
	else:
		for wave in range(2):
			var progress := (elapsed - float(wave) * 0.16) / SCAN_WAVE_DURATION
			if progress >= 0.0 and progress < 1.0:
				var radius := 24.0 + progress * (SCAN_RANGE - 24.0)
				draw_arc(_scan_origin, radius, 0.0, TAU, 96, Color("73c6c7", (1.0 - progress) * 0.75), 4.0 if wave == 0 else 2.0, true)
	if not cheese_collected and _scan_origin.distance_to(CHEESE) <= reached_radius:
		_draw_scan_marker(CHEESE, 48.0, highlight_alpha)
	if not discovery_found and _scan_origin.distance_to(DISCOVERY) <= reached_radius:
		_draw_scan_marker(DISCOVERY, 68.0, highlight_alpha)
	if not meep_rescued and _scan_origin.distance_to(meep_position) <= reached_radius:
		_draw_scan_marker(meep_position, 62.0, highlight_alpha)
		if not is_meep_talking():
			_draw_meep_text("MEEP!", meep_position + Vector2(-32, -78), Color("fff5dc", highlight_alpha))


func _draw_meep() -> void:
	var lift := 0.0
	if _meep_celebration > 0.0 and not is_meep_talking() and not SaveService.is_reduced_motion():
		lift = absf(sin((2.0 - _meep_celebration) * PI * 3.0)) * 9.0
	_draw_oval_shadow(meep_position + Vector2(0, 36), Vector2(31, 8), Color("9ebcc1"))
	draw_texture_rect(HAPPY_MEEP_ART if meep_rescued else MEEP_ART, Rect2(meep_position + Vector2(-50, -65 - lift), Vector2(100, 110)), false)
	if not is_meep_talking():
		if _meep_celebration > 0.0:
			_draw_meep_text("♥", meep_position + Vector2(-10, -80), Color("ee8978", minf(_meep_celebration / 0.4, 1.0)))
		elif not meep_rescued:
			draw_texture_rect(CHEESE_ART, Rect2(meep_position + Vector2(-15, -90), Vector2(30, 27)), false)


func _draw_meep_text(message: String, at: Vector2, color: Color) -> void:
	draw_string_outline(ThemeDB.fallback_font, at, message, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 4, Color("26394f", color.a))
	draw_string(ThemeDB.fallback_font, at, message, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, color)


func _draw_scan_marker(center: Vector2, radius: float, alpha: float) -> void:
	# Four corners frame a found clue without hiding its silhouette.
	for corner in range(4):
		var angle := float(corner) * PI * 0.5 + PI * 0.25
		draw_arc(center, radius, angle - 0.16, angle + 0.16, 8, Color("26394f", alpha), 7.0, true)
		draw_arc(center, radius, angle - 0.16, angle + 0.16, 8, Color("73c6c7", alpha), 3.0, true)


func _draw_pickup_effect() -> void:
	var progress := 1.0 - _pickup_time / PICKUP_DURATION
	var fade := minf(1.0, _pickup_time / 0.3)
	var reduced_motion := SaveService.is_reduced_motion()
	if not reduced_motion:
		var spread := 12.0 + (1.0 - pow(1.0 - progress, 3.0)) * 46.0
		for index in range(6):
			var angle := float(index) / 6.0 * TAU - PI * 0.5
			var center := CHEESE + Vector2.from_angle(angle) * spread
			var points := PackedVector2Array()
			for corner in range(8):
				var radius := 7.0 if corner % 2 == 0 else 2.5
				points.append(center + Vector2.from_angle(float(corner) / 8.0 * TAU) * radius)
			draw_colored_polygon(points, Color("f9cb65", fade))
	var rise := 0.0 if reduced_motion else progress * 30.0
	var text_position := CHEESE + Vector2(-18, -40 - rise)
	draw_string_outline(ThemeDB.fallback_font, text_position, "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 5, Color("26394f", fade))
	draw_string(ThemeDB.fallback_font, text_position, "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("f9cb65", fade))


func _draw_oval_shadow(center: Vector2, radii: Vector2, color: Color) -> void:
	draw_set_transform(center, 0.0, radii)
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO)
