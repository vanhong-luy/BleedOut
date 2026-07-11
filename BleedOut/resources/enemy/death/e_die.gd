extends Node2D

@onready var en_dead_sprite: Sprite2D = $DeadSprite


var move_dir: float
var move_spd: float = randf_range(10, 15)
var friction: float = randf_range(2, 4)



func _ready():
	move_dir = randf() * TAU
	var all_frames = en_dead_sprite.hframes * en_dead_sprite.vframes
	en_dead_sprite.frame = randi() % all_frames
	
	#blood_sprite.scale = Vector2(randf_range(0.5, 1.0), randf_range(0.5, 1.0))
	#blood_sprite.rotation = move_dir
	
func _process(_delta):
	move_spd = move_toward(move_spd, 0, friction)
	position += Vector2.RIGHT.rotated(move_dir) * move_spd


#func _draw():
	#draw_circle(Vector2.ZERO, randf_range(0.5, 4.0), Color(1.0, 0.0, 0.0, 1.0))
