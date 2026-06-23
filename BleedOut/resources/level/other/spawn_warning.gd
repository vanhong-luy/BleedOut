extends Node2D

var radius = 0.0
var max_radius = 15.0
var pulse_speed = 30.0
var alpha = 1.0

func _process(delta):
	radius += pulse_speed * delta
	if radius >= max_radius:
		radius = 0.0
	queue_redraw()

func _draw():
	draw_circle(Vector2.ZERO, radius, Color(1.0, 1.0, 1.0, alpha))
