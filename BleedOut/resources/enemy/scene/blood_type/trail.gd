extends Line2D

var previous_pos: Vector2 = Vector2.ZERO
var radius: float = 0.0

func free() -> void:
	var texture = get_parent().texture
	radius = texture.get_size().x * 0.5
	previous_pos = get_parent().global_position

func _process(_delta: float) -> void:
	var current_pos = get_parent().global_position
	var direction = (current_pos - previous_pos).normalized()
	
	add_point(current_pos - radius * direction)
	if points.size() >= 30:
		remove_point(0)
	
	previous_pos = current_pos
