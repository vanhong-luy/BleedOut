extends Node2D
class_name paint

var blood_spots: Array = []

func _ready() -> void:
	z_index = -1

func draw_blood(draw_pos: Vector2) -> void:
	blood_spots.append(draw_pos)

func flush() -> void:
	queue_redraw()

func _draw() -> void:
	for spot in blood_spots:
		draw_circle(spot, randf_range(1, 4), Color(0.6, 0, 0, 1))
