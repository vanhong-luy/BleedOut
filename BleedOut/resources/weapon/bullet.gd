extends Area2D

@onready var ray_cast: RayCast2D = $RayCast2D

var bullet_speed = 800
var damage = 0.0
var is_hit = false

func _process(delta):
	position += transform.x * bullet_speed * delta
	
	if ray_cast.is_colliding():
		if is_hit:
			return
		var collider = ray_cast.get_collider()
		if collider is TileMapLayer or collider is StaticBody2D:
			queue_free()
			
func _on_area_entered(area: Area2D):
	if is_hit:
		return
	if area is en_HurtBox:
		is_hit = true
		area.en_get_damage(damage)
		queue_free()
