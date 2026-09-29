extends Node2D

const ROCKET := Vector2(156, 382)
const CHEESE := Vector2(735, 470)
const DISCOVERY := Vector2(1000, 265)

var buddy_position := Vector2(270, 405)
var buddy_facing := Vector2.RIGHT
var cheese_collected := false
var discovery_found := false
var scan_radius := 0.0


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("101b37"))
	for star in [Vector2(90, 80), Vector2(277, 110), Vector2(420, 44), Vector2(790, 95), Vector2(1130, 90), Vector2(1200, 180)]:
		draw_circle(star, 3.0, Color("f7edbf"))
	draw_circle(Vector2(1060, 100), 44.0, Color("617fa3"))
	draw_rect(Rect2(0, 250, 1280, 470), Color("9babc1"))
	draw_polygon(PackedVector2Array([Vector2(0, 335), Vector2(155, 285), Vector2(370, 340), Vector2(610, 290), Vector2(890, 335), Vector2(1100, 280), Vector2(1280, 320), Vector2(1280, 720), Vector2(0, 720)]), PackedColorArray([Color("c7d3df")]))
	for crater in [Vector2(465, 510), Vector2(390, 635), Vector2(980, 570), Vector2(1150, 425)]:
		draw_circle(crater, 42.0, Color("8799b1"))
		draw_arc(crater, 42.0, 0.0, TAU, 32, Color("e5eaf1"), 5.0)
	# A clear rocket landing marker and a visible entrance.
	draw_polygon(PackedVector2Array([ROCKET + Vector2(-54, 74), ROCKET + Vector2(-46, -41), ROCKET + Vector2(0, -106), ROCKET + Vector2(46, -41), ROCKET + Vector2(54, 74)]), PackedColorArray([Color("f5f0dd")]))
	draw_circle(ROCKET + Vector2(0, -20), 19.0, Color("65b9de"))
	draw_rect(Rect2(ROCKET + Vector2(-28, 30), Vector2(56, 47)), Color("586b84"))
	draw_line(ROCKET + Vector2(-47, 70), ROCKET + Vector2(-76, 100), Color("e9736a"), 8.0)
	draw_line(ROCKET + Vector2(47, 70), ROCKET + Vector2(76, 100), Color("e9736a"), 8.0)
	if not cheese_collected:
		draw_polygon(PackedVector2Array([CHEESE + Vector2(-24, 20), CHEESE + Vector2(-18, -19), CHEESE + Vector2(25, 2), CHEESE + Vector2(20, 21)]), PackedColorArray([Color("fbd44a")]))
		for offset in [Vector2(-4, 1), Vector2(13, 8), Vector2(-10, 14)]:
			draw_circle(CHEESE + offset, 3.5, Color("cd9d35"))
	draw_circle(DISCOVERY, 36.0, Color("657891"))
	draw_arc(DISCOVERY, 36.0, 0.0, TAU, 32, Color("e4ecf5") if discovery_found else Color("fbd44a"), 5.0)
	draw_circle(DISCOVERY + Vector2(9, -5), 10.0, Color("344860"))
	# The Buddy is a simple, readable placeholder character.
	draw_ellipse_placeholder(buddy_position + Vector2(0, 25), Vector2(26, 9), Color(0.17, 0.25, 0.38, 0.4))
	draw_circle(buddy_position, 24.0, Color("f8f0dd"))
	draw_circle(buddy_position + Vector2(-8, -5), 3.0, Color("30425c"))
	draw_circle(buddy_position + Vector2(8, -5), 3.0, Color("30425c"))
	draw_line(buddy_position + Vector2(-8, 8), buddy_position + Vector2(8, 8), Color("e57368"), 3.0)
	draw_line(buddy_position + Vector2(0, -22), buddy_position + buddy_facing * 22.0 + Vector2(0, -30), Color("fbd44a"), 4.0)
	if scan_radius > 0.0:
		draw_arc(buddy_position, scan_radius, 0.0, TAU, 64, Color("78e0dd", 0.75), 4.0)
		if not cheese_collected and buddy_position.distance_to(CHEESE) <= 300.0:
			draw_arc(CHEESE, 39.0, 0.0, TAU, 32, Color("78e0dd"), 4.0)
		if not discovery_found and buddy_position.distance_to(DISCOVERY) <= 300.0:
			draw_arc(DISCOVERY, 52.0, 0.0, TAU, 32, Color("78e0dd"), 4.0)


func draw_ellipse_placeholder(center: Vector2, radii: Vector2, color: Color) -> void:
	draw_set_transform(center, 0.0, radii)
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO)
