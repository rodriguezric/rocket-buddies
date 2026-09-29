extends Node2D

const BACKGROUND: Texture2D = preload("res://assets/art/moon/background.svg")
const BUDDY: Texture2D = preload("res://assets/art/moon/buddy.svg")
const ROCKET_ART: Texture2D = preload("res://assets/art/moon/rocket.svg")
const CHEESE_ART: Texture2D = preload("res://assets/art/moon/cheese.svg")
const CRATER_ART: Texture2D = preload("res://assets/art/moon/crater.svg")

const ROCKET := Vector2(156, 382)
const CHEESE := Vector2(735, 470)
const DISCOVERY := Vector2(1000, 265)

var buddy_position := Vector2(270, 405)
var buddy_facing := Vector2.RIGHT
var cheese_collected := false
var discovery_found := false
var scan_radius := 0.0


func _draw() -> void:
	draw_texture_rect(BACKGROUND, Rect2(0, 0, 1280, 720), false)
	draw_texture_rect(ROCKET_ART, Rect2(ROCKET + Vector2(-80, -130), Vector2(160, 220)), false)
	draw_texture_rect(CRATER_ART, Rect2(DISCOVERY + Vector2(-65, -50), Vector2(130, 100)), false)
	if not cheese_collected:
		draw_texture_rect(CHEESE_ART, Rect2(CHEESE + Vector2(-45, -40), Vector2(90, 80)), false)
	if discovery_found:
		draw_circle(DISCOVERY + Vector2(49, -37), 13.0, Color("73c6c7"))
		draw_line(DISCOVERY + Vector2(43, -37), DISCOVERY + Vector2(48, -31), Color("26394f"), 3.0)
		draw_line(DISCOVERY + Vector2(48, -31), DISCOVERY + Vector2(56, -43), Color("26394f"), 3.0)
	if scan_radius > 0.0:
		draw_arc(buddy_position, scan_radius, 0.0, TAU, 64, Color("73c6c7", 0.85), 5.0)
		if not cheese_collected and buddy_position.distance_to(CHEESE) <= 300.0:
			draw_arc(CHEESE, 46.0, 0.0, TAU, 32, Color("73c6c7"), 4.0)
		if not discovery_found and buddy_position.distance_to(DISCOVERY) <= 300.0:
			draw_arc(DISCOVERY, 66.0, 0.0, TAU, 32, Color("73c6c7"), 4.0)
	_draw_oval_shadow(buddy_position + Vector2(0, 22), Vector2(28, 8), Color("9ebcc1"))
	draw_set_transform(buddy_position + Vector2(0, -24), 0.0, Vector2(-1.0 if buddy_facing.x < -0.15 else 1.0, 1.0))
	draw_texture_rect(BUDDY, Rect2(-48, -56, 96, 112), false)
	draw_set_transform(Vector2.ZERO)


func _draw_oval_shadow(center: Vector2, radii: Vector2, color: Color) -> void:
	draw_set_transform(center, 0.0, radii)
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO)
