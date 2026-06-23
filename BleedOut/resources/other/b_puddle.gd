extends Node2D

@onready var blood_sprite: Sprite2D = $BloodSprite


var move_dir: float
var move_spd: float = randf_range(15, 20)
var friction: float = randf_range(4, 8)

func _ready():
	#move_dir = randf() * TAU
	var all_frames = blood_sprite.hframes * blood_sprite.vframes
	blood_sprite.frame = randi() % all_frames
	
	blood_sprite.scale = Vector2(randf_range(1.0, 1.5), randf_range(1.0, 1.5))
	blood_sprite.rotation = randf() * TAU

func _process(_delta):
	move_spd = move_toward(move_spd, 0, friction)
	position += Vector2.RIGHT.rotated(move_dir) * move_spd
