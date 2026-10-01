extends Node2D

const BACKGROUND: Texture2D = preload("res://assets/art/moon/background.svg")
const BUDDY: Texture2D = preload("res://assets/art/moon/buddy.svg")
const CHEESE: Texture2D = preload("res://assets/art/moon/cheese.svg")
const INK := Color("26394f")
const CREAM := Color("fff5dc")
const TEAL := Color("73c6c7")
const GOLD := Color("f9cb65")
const CORAL := Color("ee8978")
const GRID_COLUMNS := 5
const GRID_ROWS := 3
const GRID_ORIGIN := Vector2(342, 238)
const GRID_STEP := Vector2(145, 114)

var buddy_position := Vector2(-100, 411)
var selected := Vector2i(2, 1)
var found_cells: Array[Vector2i] = []
var empty_cells: Array[Vector2i] = []
var scan_marks: Dictionary = {}
var scan_cell := Vector2i(-1, -1)
var scan_heat := 0
var scan_time := 0.0
var dig_cell := Vector2i(-1, -1)
var dig_time := 0.0
var dig_success := false
var pickup_cell := Vector2i(-1, -1)
var pickup_time := 0.0
var celebrating := false
var celebration_time := 0.0
var _clock := 0.0


func reset() -> void:
	buddy_position = Vector2(-100, 411)
	selected = Vector2i(2, 1)
	found_cells.clear()
	empty_cells.clear()
	scan_marks.clear()
	scan_cell = Vector2i(-1, -1)
	scan_time = 0.0
	dig_cell = Vector2i(-1, -1)
	dig_time = 0.0
	pickup_cell = Vector2i(-1, -1)
	pickup_time = 0.0
	celebrating = false
	celebration_time = 0.0
	_clock = 0.0
	queue_redraw()


func cell_center(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell.x * GRID_STEP.x, cell.y * GRID_STEP.y)


func cell_at(point: Vector2) -> Vector2i:
	var column := roundi((point.x - GRID_ORIGIN.x) / GRID_STEP.x)
	var row := roundi((point.y - GRID_ORIGIN.y) / GRID_STEP.y)
	if column < 0 or column >= GRID_COLUMNS or row < 0 or row >= GRID_ROWS:
		return Vector2i(-1, -1)
	var cell := Vector2i(column, row)
	return cell if point.distance_to(cell_center(cell)) <= 53.0 else Vector2i(-1, -1)


func play_scan(heat: int) -> void:
	scan_cell = selected
	scan_heat = heat
	scan_time = 0.9
	scan_marks[selected] = heat
	queue_redraw()


func play_dig(success: bool) -> void:
	dig_cell = selected
	dig_success = success
	dig_time = 0.85
	if success:
		pickup_cell = selected
		pickup_time = 1.25
	queue_redraw()


func _process(delta: float) -> void:
	_clock += delta
	scan_time = maxf(0.0, scan_time - delta)
	dig_time = maxf(0.0, dig_time - delta)
	pickup_time = maxf(0.0, pickup_time - delta)
	if celebrating:
		celebration_time += delta
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(BACKGROUND, Rect2(0, 0, 1280, 720), false)
	draw_rect(Rect2(267, 172, 785, 349), Color(INK, 0.88))
	draw_rect(Rect2(267, 172, 785, 349), Color(TEAL, 0.75), false, 3.0)
	_draw_buddy()
	for row in range(GRID_ROWS):
		for column in range(GRID_COLUMNS):
			_draw_cell(Vector2i(column, row))
	if scan_time > 0.0:
		_draw_scan_effect()
	if dig_time > 0.0:
		_draw_dig_effect()
	if pickup_time > 0.0:
		_draw_pickup_effect()
	if celebrating:
		_draw_celebration()


func _draw_buddy() -> void:
	var bob := 0.0 if SaveService.is_reduced_motion() else sin(_clock * 4.0) * 3.0
	draw_ellipse_shadow(buddy_position + Vector2(0, 46), Vector2(43, 11))
	draw_texture_rect(BUDDY, Rect2(buddy_position + Vector2(-60, -80 + bob), Vector2(120, 140)), false)
	if scan_time > 0.0:
		var end := cell_center(scan_cell)
		draw_line(buddy_position + Vector2(28, -30), end, Color(TEAL, scan_time * 0.46), 4.0)
		draw_circle(buddy_position + Vector2(28, -30), 10.0, Color(TEAL, scan_time))


func draw_ellipse_shadow(at: Vector2, radius: Vector2) -> void:
	draw_set_transform(at, 0.0, radius)
	draw_circle(Vector2.ZERO, 1.0, Color(INK, 0.35))
	draw_set_transform(Vector2.ZERO)


func _draw_cell(cell: Vector2i) -> void:
	var center := cell_center(cell)
	var is_selected := cell == selected
	var is_found := found_cells.has(cell)
	var is_empty := empty_cells.has(cell)
	var lift := 0.0 if SaveService.is_reduced_motion() or not is_selected else sin(_clock * 5.0) * 2.5
	center.y += lift
	draw_circle(center + Vector2(0, 6), 51.0, Color("182b44"))
	draw_circle(center, 50.0, Color("9ebcc1") if not is_found else Color("617e89"))
	draw_circle(center + Vector2(-9, -8), 34.0, Color("bfd0d1", 0.55) if not is_found else Color("26394f", 0.45))
	draw_arc(center, 50.0, 0.0, TAU, 48, GOLD if is_selected else Color("d8e0df"), 5.0 if is_selected else 2.0)
	if is_found:
		draw_texture_rect(CHEESE, Rect2(center - Vector2(31, 28), Vector2(62, 56)), false)
	elif is_empty:
		draw_line(center + Vector2(-12, -12), center + Vector2(12, 12), Color(INK, 0.75), 3.0)
		draw_line(center + Vector2(12, -12), center + Vector2(-12, 12), Color(INK, 0.75), 3.0)
	elif scan_marks.has(cell):
		var heat: int = scan_marks[cell]
		var mark_color := GOLD if heat >= 2 else TEAL
		draw_circle(center + Vector2(0, -2), 11.0 + heat * 3.0, Color(mark_color, 0.65))
		draw_circle(center + Vector2(0, -2), 4.0, CREAM)
	if is_selected:
		var arrow_points := PackedVector2Array([center + Vector2(0, -76), center + Vector2(-12, -95), center + Vector2(12, -95)])
		draw_colored_polygon(arrow_points, GOLD)


func _draw_scan_effect() -> void:
	var center := cell_center(scan_cell)
	var progress := 1.0 - scan_time / 0.9
	if SaveService.is_reduced_motion():
		draw_arc(center, 61.0, 0.0, TAU, 48, Color(TEAL, scan_time * 0.6), 3.0)
	else:
		for wave in range(2):
			var amount := clampf((progress - wave * 0.18) / 0.82, 0.0, 1.0)
			if amount > 0.0 and amount < 1.0:
				draw_arc(center, 28.0 + amount * 175.0, 0.0, TAU, 80, Color(TEAL, (1.0 - amount) * 0.8), 3.0)
	var text := "!" if scan_heat >= 3 else ("HOT" if scan_heat == 2 else ("WARM" if scan_heat == 1 else "FAINT"))
	_draw_popup(text, center + Vector2(-34, -63 - progress * 25.0), GOLD if scan_heat >= 2 else TEAL, scan_time / 0.9)


func _draw_dig_effect() -> void:
	var center := cell_center(dig_cell)
	var progress := 1.0 - dig_time / 0.85
	for index in range(8):
		var angle := index * TAU / 8.0
		var offset := Vector2.RIGHT.rotated(angle) * (18.0 + progress * 66.0)
		if SaveService.is_reduced_motion():
			offset = Vector2.RIGHT.rotated(angle) * 42.0
		draw_circle(center + offset, 7.0 * (1.0 - progress), Color(GOLD if dig_success else CREAM, (1.0 - progress) * 0.85))
	_draw_popup("FOUND!" if dig_success else "POOF!", center + Vector2(-44, -72 - progress * 24.0), GOLD if dig_success else CREAM, dig_time / 0.85)


func _draw_pickup_effect() -> void:
	var center := cell_center(pickup_cell)
	var progress := 1.0 - pickup_time / 1.25
	var rise := 0.0 if SaveService.is_reduced_motion() else progress * 95.0
	draw_texture_rect(CHEESE, Rect2(center + Vector2(-34, -35 - rise), Vector2(68, 60)), false, Color(CREAM, pickup_time / 1.25))
	for index in range(5):
		var angle := index * TAU / 5.0 + _clock
		draw_circle(center + Vector2.RIGHT.rotated(angle) * (45.0 + progress * 38.0), 4.0, Color(GOLD, pickup_time / 1.25))


func _draw_celebration() -> void:
	for index in range(14):
		var angle := index * TAU / 14.0
		var spread := 95.0 if SaveService.is_reduced_motion() else 60.0 + fmod(celebration_time * 75.0 + index * 18.0, 150.0)
		var point := Vector2(660, 344) + Vector2.RIGHT.rotated(angle) * spread
		draw_circle(point, 5.0, GOLD if index % 2 == 0 else TEAL)


func _draw_popup(message: String, at: Vector2, color: Color, opacity: float) -> void:
	draw_string_outline(ThemeDB.fallback_font, at, message, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, 4, Color(INK, opacity))
	draw_string(ThemeDB.fallback_font, at, message, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color(color, opacity))
