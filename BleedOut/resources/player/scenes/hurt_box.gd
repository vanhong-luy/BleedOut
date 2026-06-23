extends Area2D

class_name HurtBox

signal hurted(hit_from: Vector2)
signal died(hit_from: Vector2)

@onready var top: AnimatedSprite2D = $"../top"
@export var healthpoint = 100

func _process(_delta):
	rotation = top.rotation

func get_damage(value: int, hit_from: Vector2 = Vector2.ZERO):
	
	if get_parent().invincible:
		return
	
	healthpoint -= value
	#print("Current Health:", healthpoint)
	hurted.emit(hit_from)
	
	if healthpoint <= 0:
		died.emit(hit_from)

func set_h_active(boolean: bool):
	for child in get_children():
		if child is not CollisionShape2D: continue
		
		#child.disabled = not boolean
		child.set_deferred("disabled", not boolean)
		
