extends Sprite2D

@export var fps: float = 10.0
var frame_time: float = 0.0

func _process(delta: float) -> void:
	frame_time += delta
	if frame_time >= 1.0 / fps:
		frame_time = 0.0
		frame = (frame + 1) % (hframes * vframes)
