extends Node2D

const ROCKET_ART: Texture2D = preload("res://assets/art/moon/rocket.svg")
const CHEESE_ART: Texture2D = preload("res://assets/art/moon/cheese.svg")
const INK := Color("26394f")
const CREAM := Color("fff5dc")
const TEAL := Color("73c6c7")
const CORAL := Color("ee8978")
const GOLD := Color("f9cb65")
const ENTITY_SPEED := 370.0

var ship_position := Vector2(300, 365)
var ship_scale := 0.75
var ship_tilt := 0.0
var flight_progress := 0.0
var speed_factor := 1.0
var stage: StringName = &"launching"
var entities: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var comet_time := 0.0
var impact_time := 0.0
var pickup_time := 0.0
var invulnerable_time := 0.0
var _clock := 0.0
var _star_scroll := 0.0
var _stars: Array[Dictionary] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2086
	for index in range(76):
		_stars.append({"position": Vector2(rng.randf_range(0.0, 1280.0), rng.randf_range(15.0, 650.0)), "size": rng.randf_range(1.0, 3.2), "depth": rng.randf_range(0.35, 1.1)})


func reset() -> void:
	ship_position = Vector2(-160, 365)
	ship_scale = 0.75
	ship_tilt = 0.0
	flight_progress = 0.0
	speed_factor = 1.0
	stage = &"launching"
	entities.clear()
	effects.clear()
	comet_time = 0.0
	impact_time = 0.0
	pickup_time = 0.0
	invulnerable_time = 0.0
	_clock = 0.0
	_star_scroll = 0.0
	queue_redraw()


func update_world(delta: float) -> void:
	_clock += delta
	_star_scroll += delta * speed_factor
	impact_time = maxf(0.0, impact_time - delta)
	pickup_time = maxf(0.0, pickup_time - delta)
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	comet_time = maxf(0.0, comet_time - delta)
	for index in range(entities.size() - 1, -1, -1):
		var entity: Dictionary = entities[index]
		entity["position"] = (entity["position"] as Vector2) + Vector2.LEFT * delta * ENTITY_SPEED * speed_factor
		entity["spin"] = float(entity["spin"]) + delta * float(entity["spin_rate"])
		entities[index] = entity
		if (entity["position"] as Vector2).x < -110.0:
			entities.remove_at(index)
	for index in range(effects.size() - 1, -1, -1):
		var effect: Dictionary = effects[index]
		effect["age"] = float(effect["age"]) + delta
		effects[index] = effect
		if float(effect["age"]) >= float(effect["duration"]):
			effects.remove_at(index)
	queue_redraw()


func burst(at: Vector2, color: Color, label := "") -> void:
	effects.append({"position": at, "color": color, "label": label, "age": 0.0, "duration": 0.85})
	queue_redraw()


func get_comet_position() -> Vector2:
	var progress := 1.0 - comet_time / 4.4
	return Vector2(1350.0 - progress * 1500.0, 235.0 + progress * 130.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("182b44"))
	_draw_stars()
	_draw_moon()
	if comet_time > 0.0:
		_draw_comet()
	for entity in entities:
		_draw_entity(entity)
	for effect in effects:
		_draw_effect(effect)
	_draw_ship()
	if impact_time > 0.0 and not SaveService.is_reduced_motion():
		draw_rect(Rect2(0, 0, 1280, 720), Color(CORAL, impact_time * 0.13))


func _draw_stars() -> void:
	var reduced := SaveService.is_reduced_motion()
	for star in _stars:
		var original: Vector2 = star["position"]
		var depth: float = star["depth"]
		var x := original.x if reduced else fposmod(original.x - _star_scroll * (22.0 + 78.0 * depth), 1280.0)
		var radius: float = star["size"]
		var glow := 0.7 if reduced else 0.55 + 0.3 * sin(_clock * 2.0 + original.x)
		draw_circle(Vector2(x, original.y), radius, Color(CREAM, glow))
		if radius > 2.5:
			draw_line(Vector2(x - 5.0, original.y), Vector2(x + 5.0, original.y), Color(CREAM, glow * 0.5), 1.5)


func _draw_moon() -> void:
	var progress := clampf((flight_progress - 0.42) / 0.58, 0.0, 1.0)
	var radius := lerpf(44.0, 190.0, progress)
	var center := Vector2(1175.0 - 50.0 * progress, 365.0)
	if progress > 0.02:
		draw_circle(center, radius + 18.0, Color(TEAL, 0.1 + progress * 0.12))
	draw_circle(center, radius, Color("d8e0df"))
	draw_circle(center + Vector2(-radius * 0.27, -radius * 0.2), radius * 0.18, Color("bfd0d1"))
	draw_circle(center + Vector2(radius * 0.34, radius * 0.25), radius * 0.11, Color("bfd0d1"))
	draw_arc(center + Vector2(-radius * 0.27, -radius * 0.2), radius * 0.18, 0.0, TAU, 32, Color("9ebcc1"), 2.0)
	draw_arc(center, radius, 0.0, TAU, 80, INK, 5.0)


func _draw_comet() -> void:
	var point := get_comet_position()
	for index in range(4):
		draw_circle(point + Vector2(37.0 + index * 22.0, -9.0 - index * 7.0), 26.0 - index * 5.0, Color(GOLD, (0.5 - index * 0.1) * comet_time / 4.4))
	draw_texture_rect(CHEESE_ART, Rect2(point - Vector2(37, 33), Vector2(74, 66)), false)


func _draw_entity(entity: Dictionary) -> void:
	var point: Vector2 = entity["position"]
	var kind: StringName = entity["kind"]
	var spin: float = entity["spin"]
	var pulse := 1.0 if SaveService.is_reduced_motion() else 1.0 + sin(_clock * 7.0 + point.y) * 0.09
	draw_set_transform(point, spin, Vector2.ONE * pulse)
	match kind:
		&"asteroid":
			var outline := PackedVector2Array([Vector2(-31, -11), Vector2(-17, -31), Vector2(13, -33), Vector2(36, -9), Vector2(27, 25), Vector2(-7, 34), Vector2(-32, 13)])
			draw_colored_polygon(outline, Color("9ebcc1"))
			draw_polyline(outline + PackedVector2Array([outline[0]]), INK, 4.0, true)
			draw_circle(Vector2(-8, -9), 8.0, Color("bfd0d1"))
			draw_circle(Vector2(14, 11), 5.0, Color("bfd0d1"))
		&"fuel":
			draw_circle(Vector2.ZERO, 29.0, Color(TEAL, 0.2))
			draw_rect(Rect2(-17, -19, 34, 39), CREAM)
			draw_rect(Rect2(-17, -19, 34, 39), INK, false, 3.0)
			draw_rect(Rect2(-11, -12, 22, 25), TEAL)
			draw_rect(Rect2(-5, -25, 10, 7), CORAL)
		&"stardust":
			draw_circle(Vector2.ZERO, 27.0, Color(GOLD, 0.2))
			var points := PackedVector2Array([Vector2(0, -22), Vector2(6, -6), Vector2(22, 0), Vector2(6, 6), Vector2(0, 22), Vector2(-6, 6), Vector2(-22, 0), Vector2(-6, -6)])
			draw_colored_polygon(points, GOLD)
			draw_polyline(points + PackedVector2Array([points[0]]), INK, 2.5, true)
	draw_set_transform(Vector2.ZERO)


func _draw_effect(effect: Dictionary) -> void:
	var age: float = effect["age"]
	var duration: float = effect["duration"]
	var point: Vector2 = effect["position"]
	var color: Color = effect["color"]
	var alpha := 1.0 - age / duration
	if not SaveService.is_reduced_motion():
		for index in range(8):
			var angle := float(index) / 8.0 * TAU
			var offset := Vector2.RIGHT.rotated(angle) * (12.0 + age * 75.0)
			draw_circle(point + offset, 5.0 * alpha, Color(color, alpha))
	else:
		draw_arc(point, 35.0, 0.0, TAU, 48, Color(color, alpha * 0.6), 2.0)
	var label: String = effect["label"]
	if not label.is_empty():
		var text_point := point + Vector2(-25, -42 - (0.0 if SaveService.is_reduced_motion() else age * 38.0))
		draw_string_outline(ThemeDB.fallback_font, text_point, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 4, Color(INK, alpha))
		draw_string(ThemeDB.fallback_font, text_point, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(color, alpha))


func _draw_ship() -> void:
	if invulnerable_time > 0.0 and not SaveService.is_reduced_motion() and sin(_clock * 24.0) < -0.25:
		return
	var shake := Vector2.ZERO
	if impact_time > 0.0 and not SaveService.is_reduced_motion():
		shake = Vector2(sin(_clock * 73.0) * 5.0, cos(_clock * 63.0) * 4.0) * impact_time
	var bob := 0.0 if SaveService.is_reduced_motion() else sin(_clock * 4.5) * 2.5
	draw_set_transform(ship_position + shake + Vector2(0, bob), PI * 0.5 + ship_tilt, Vector2.ONE * ship_scale)
	if stage != &"finished":
		var flame := 45.0 if SaveService.is_reduced_motion() else 42.0 + sin(_clock * 27.0) * 8.0
		draw_colored_polygon(PackedVector2Array([Vector2(-17, 68), Vector2(0, 68 + flame * speed_factor), Vector2(17, 68)]), GOLD)
		draw_colored_polygon(PackedVector2Array([Vector2(-9, 68), Vector2(0, 89 + flame * 0.45), Vector2(9, 68)]), CREAM)
	draw_texture_rect(ROCKET_ART, Rect2(-80, -110, 160, 220), false)
	if pickup_time > 0.0:
		draw_arc(Vector2.ZERO, 112.0, 0.0, TAU, 64, Color(GOLD, pickup_time * 0.6), 3.0)
	draw_set_transform(Vector2.ZERO)
