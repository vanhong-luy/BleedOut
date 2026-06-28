#this is, my, BOOMSTICK!
extends Node2D

@onready var top: AnimatedSprite2D = $"../.."
@onready var player = get_tree().get_first_node_in_group("player")
@onready var camera: Camera2D = get_viewport().get_camera_2d()

#@onready var pistol_anim: AnimationPlayer = $"../../../Node2D/PistolAnim"
@export var pallet = 8
@export var spread_angle = 20 #what does he even do?
@export var arc: float = 20

const BULLET = preload("uid://cp15xcknlrfht")

@onready var gunpoint: Marker2D = $Gunpoint


var active = false
var can_shoot = true

func set_active_weapon(value: bool):
	active = value

func _process(_delta):
	if !active or !player.is_holding_second or player.is_dead:
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
	#print("yo, im being called")
	var w = player.weapons[player.current_weapon]
	w.mag_cap -= 1
	can_shoot = false
	
	#pistol_anim.play("attack")
	
	for i in range(pallet):
		var arc_rad = deg_to_rad(randf_range(-arc, arc))
		var bullet = BULLET.instantiate()
		get_tree().root.add_child(bullet)
		bullet.global_position = gunpoint.global_position
		bullet.damage = w.damage
		
		var offset = randf_range(-arc_rad, arc_rad)
		bullet.rotation = top.rotation + deg_to_rad(-90) + offset
	camera.applyShake()
	
	await get_tree().create_timer(w.fire_rate).timeout
	can_shoot = true
	
	if w.mag_cap == 0:
		player.reload()
