extends Area2D

class_name en_HitBox
@onready var top: AnimatedSprite2D = $"../top"

var damage: float = 20.0

func _ready() -> void:
	set_active(false)


func _process(_delta):
	rotation = top.rotation
	
func set_active(boolean: bool):
	for child in get_children():
		if child is not CollisionShape2D: continue
		
		#child.disabled = not boolean
		child.set_deferred("disabled", not boolean)

func _on_area_entered(area: Area2D) -> void:
	if set_active(false):
		return
	
	if area is HurtBox:
		area.get_damage(damage, global_position)
