extends Area2D

class_name HitBox
@onready var top: AnimatedSprite2D = $"../top"
@onready var hurt_box: HurtBox = $"../HurtBox"
var camera: Camera2D
@onready var bat: Node2D = $"."

var damage: float = 0.5
#var loot_blood: int = 20

func _ready() -> void:
	call_deferred("get_camera")
	set_active(false)

func get_camera():
	camera = get_viewport().get_camera_2d()

func _process(delta):
	rotation = top.rotation
	
	if camera == null:
		return
	
	if camera.shakeStrength > 0:
		camera.shakeStrength = lerpf(camera.shakeStrength, 0, camera.shakeFade * delta)
		
		camera.offset = camera.randomOffset()
		
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
		#print("damage dealth:", damage)
		camera.applyShake()

		#hurt_box.healthpoint += loot_blood

		if hurt_box.healthpoint > 100:
			hurt_box.healthpoint = 100
			
		#print("Current Health after heal:" ,hurt_box.healthpoint)
