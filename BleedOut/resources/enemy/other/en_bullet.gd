extends Area2D

@onready var ray_cast: RayCast2D = $RayCast2D

var bullet_speed = 1000 #it's sniper bullet :D
var damage = 0.0

func _process(delta):
	position += transform.x * bullet_speed * delta
	
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider is TileMapLayer or collider is StaticBody2D:
			queue_free()
			
func _on_area_entered(area: Area2D):
	if area is HurtBox:
		area.get_damage(damage)
		queue_free()
