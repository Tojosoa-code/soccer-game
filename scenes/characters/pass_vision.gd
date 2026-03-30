class_name PassVision
extends Node2D



func _draw() -> void:
	var center := Vector2.ZERO
	
	# 1. Cercle avec bordure
	draw_circle(center, circle_radius, Color(0,0,0,0)) # fond transparent
	draw_arc(center, circle_radius, 0, TAU, 64, border_color, border_width)
	
	# 2. Triangle équilatéral sur le bord du cercle
	var angle := deg_to_rad(direction_angle_deg)
	var base_center := center + Vector2(cos(angle), sin(angle)) * circle_radius
	
	# Calcul des 3 sommets du triangle équilatéral
	var tip := center + Vector2(cos(angle), sin(angle)) * (circle_radius + triangle_size)
	var offset := triangle_size * 0.6  # ajustement pour équilatéral
	var base_left := base_center + Vector2(cos(angle + PI/2), sin(angle + PI/2)) * offset
	var base_right := base_center + Vector2(cos(angle - PI/2), sin(angle - PI/2)) * offset
	
	var triangle := PackedVector2Array([tip, base_left, base_right])
	draw_polygon(triangle, [triangle_color])
