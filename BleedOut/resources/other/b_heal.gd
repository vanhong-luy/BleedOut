extends Area2D

@onready var blood_sprite: Sprite2D = $BloodSprite


var move_dir: float
var move_spd: float = randf_range(15, 20)
var friction: float = randf_range(2, 4)
var lifesteal: float = 0.0 #idk why, but if it's int, it won't work
var lifespan: float = 1.0 #timeout, don't ask me
var is_collected: bool = false

@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	#move_dir = randf() * TAU
	move_dir = randf() * TAU
	var all_frames = blood_sprite.hframes * blood_sprite.vframes
	blood_sprite.frame = randi() % all_frames
	
	blood_sprite.scale = Vector2(randf_range(0.5, 1.0), randf_range(0.5, 1.0))
	blood_sprite.rotation = move_dir
	queue_redraw()

func _process(delta):
	lifespan -= delta
	if lifespan <= 0:
		queue_free()
		
	move_spd = move_toward(move_spd, 0, friction)
	position += Vector2.RIGHT.rotated(move_dir) * move_spd


func _on_area_entered(area):
	if is_collected:
		return
	if area is HurtBox:
		#print("Healing: ", lifesteal)
		player.heal(lifesteal)
		queue_free()
