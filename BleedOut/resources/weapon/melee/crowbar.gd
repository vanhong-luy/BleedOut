extends Node2D

@onready var top: AnimatedSprite2D = $"../.."
@onready var player = get_tree().get_first_node_in_group("player")
#@onready var hit_box: HitBox = $HitBox


var step = 1
var can_swing = true

func _process(_delta: float) -> void:
	
	#if player.is_dead:
		#hit_box.set_deferred("disabled", true)
	
	if Input.is_action_just_pressed("attack") and top.animation == "melee_atk" and top.animation_finished:
		can_swing = true
		flip()
		await get_tree().create_timer(0.2).timeout
		can_swing = false

func flip():
	
	if can_swing:
		if step == 1:
			scale.x = -1
			await get_tree().create_timer(0.2).timeout
			step = 2
		elif step == 2:
			scale.x = 1
			await get_tree().create_timer(0.2).timeout
			step = 1
	else:
		return
		
