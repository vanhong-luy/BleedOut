extends Area2D

@onready var ray_cast: RayCast2D = $RayCast2D
@onready var player = get_tree().get_first_node_in_group("player")

var bullet_speed = 800
var launch_force = 300
var damage = 0.0

func _process(delta):
	
	position += transform.x * bullet_speed * delta
	
	await get_tree().create_timer(1.5).timeout
	queue_free()
	#if ray_cast.is_colliding():
		#var collider = ray_cast.get_collider()
		#if collider is TileMapLayer or collider is StaticBody2D:
			#queue_free()
			
func _on_area_entered(area: Area2D):
	if area is HurtBox:
		var shock_direction = (player.global_position - global_position).normalized()
		player.apply_knockback(shock_direction * launch_force)
		area.get_damage(damage)
