#im not sure if this still use anymore, lmk
#yes, this still use

#ok the emitting signal is a scam, i don't think we still use it

extends Area2D

@onready var top: AnimatedSprite2D = $"../top"
@onready var basic_enemy: CharacterBody2D = $".."

signal reached_melee()
signal stop_attack()

func _process(_delta):
	rotation = top.rotation

func _on_area_entered(area: Area2D) -> void:
	#if basic_enemy.is_dead:
		#return
	
	if area is HurtBox:
		reached_melee.emit()
	else:
		stop_attack.emit()
