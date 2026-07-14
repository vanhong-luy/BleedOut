extends Node2D

@onready var top: AnimatedSprite2D = $"../.."
@onready var player = get_tree().get_first_node_in_group("player")
@onready var camera: Camera2D = get_viewport().get_camera_2d()

@onready var pistol_anim: AnimationPlayer = $"../../../Node2D/PistolAnim"
@onready var flash: Sprite2D = $Flash
@onready var gunpoint: Marker2D = $Gunpoint


const BULLET = preload("uid://cp15xcknlrfht")

var active = false
var can_shoot = true

func set_active_weapon(value: bool):
	active = value

func _process(_delta):
	if !active or !player.is_holding_pistol or player.is_dead:
		return
	
	if Input.is_action_just_pressed("attack") and can_shoot and !player.is_reloading:
		var w = player.weapons[player.current_weapon]
		if w.mag_cap <= 0:
			player.reload()
			return
		shoot()
		
	if Input.is_action_just_pressed("reload") and !player.is_reloading:
		player.reload()

func shoot():
	var w = player.weapons[player.current_weapon]
	w.mag_cap -= 1
	can_shoot = false
	
	pistol_anim.play("attack")
	
	var bullet_instance = BULLET.instantiate()
	get_tree().root.add_child(bullet_instance)
	bullet_instance.global_position = gunpoint.global_position
	bullet_instance.rotation = top.rotation + deg_to_rad(-90)
	bullet_instance.damage = w.damage
	camera.applyShake()
	
	await get_tree().create_timer(w.fire_rate).timeout
	can_shoot = true
	
	if w.mag_cap == 0:
		player.reload()
		
func flashing():
	flash.visible = true
	await get_tree().create_timer(0.1).timeout
	flash.visible = false
