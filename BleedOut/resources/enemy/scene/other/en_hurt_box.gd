extends Area2D

class_name en_HurtBox

signal hurted(value: float) #don't listen to him
signal died(value: float) #don't listen to him

@onready var top: AnimatedSprite2D = $"../top"
@export var en_healthpoint: float

func _process(_delta):
	rotation = top.rotation

func en_get_damage(value: float):
	en_healthpoint -= value
	call_deferred("emit_signal", "hurted", value)
	
	if en_healthpoint <= 0:
		call_deferred("emit_signal", "died")

func set_h_active(boolean: bool):
	for child in get_children():
		if child is not CollisionShape2D: continue
		
		#child.disabled = not boolean
		child.set_deferred("disabled", not boolean)
		
