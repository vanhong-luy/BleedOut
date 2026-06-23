#There was nothing inside, but memories left abandoned

extends Area2D
class_name BulletHitBox

var damage: float = 10

func set_active(boolean: bool):
	for child in get_children():
		if child is not CollisionShape2D: continue
		
		#child.disabled = not boolean
		child.set_deferred("disabled", not boolean)

func _on_area_entered(area: Area2D) -> void:
	if set_active(false):
		return
	
	if area is en_HurtBox:
		area.en_get_damage(damage)
		print(damage)
