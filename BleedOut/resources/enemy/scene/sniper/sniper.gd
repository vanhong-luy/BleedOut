extends CharacterBody2D
@onready var top: AnimatedSprite2D = $top
@onready var legs: AnimatedSprite2D = $legs

@onready var en_hurt_box: en_HurtBox = $EnHurtBox

#RayCasting
@onready var laser: RayCast2D = $top/Laser
@onready var line: Line2D = $top/Laser/Line2D


#Camera
@onready var camera: Camera2D = get_viewport().get_camera_2d()

#Reload
var current_ammo = 0
var max_ammo = 12
var is_reloading = false
signal reload_time

#Gunpoint
@onready var gun_point: Marker2D = $top/GunPoint


@onready var col:= $EnHurtBox/CollisionShape2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D

@export var data: Enemy

@onready var player = get_tree().get_first_node_in_group("player")

var b_puddle = preload("res://resources/other/b_puddle.tscn")
var b_spread = preload("res://resources/other/b_spread.tscn")
var b_heal = preload("res://resources/other/b_heal.tscn")
var b_fly = preload("res://resources/other/b_fly.tscn")
var e_die = preload("res://resources/enemy/death/sniper_die.tscn")

@export var speed: float = 150
var min_dis: float = 50
var max_dis: float = 150

@export var projectile: PackedScene
@onready var timer: Timer = $Timer


@onready var is_dead = false

var is_attack = false
var can_attack: bool = true

var is_outside_melee_range = true

signal died

var death_list:= []

func _ready() -> void:
	en_hurt_box.en_healthpoint = data.healthpoint
	
	#Gruppa krovi na rukave

	death_list = ["die_1", "die_2", "die_3", "die_4"]
	
	can_attack = false
	await get_tree().create_timer(1.0).timeout
	can_attack = true

func _physics_process(_delta):
	if is_dead:
		line.hide()
		return
	if player.is_dead:
		top.play("idle")
		legs.play("idle")
		return
		
	if current_ammo == max_ammo and not is_reloading:
		reload_time.emit()
	
	var laser_end_pos
	if laser.is_colliding():
		laser_end_pos = laser.to_local(laser.get_collision_point())
	else:
		laser_end_pos = to_local(player.global_position)
	line.points[1] = laser_end_pos
	
	if player:
		var direction = (player.global_position - global_position).normalized()
		top.rotation = direction.angle() + deg_to_rad(90)
		
		if laser.is_colliding() and laser.get_collider() == player:
			attack()
		else:
			top.play("idle")
	
	move_and_slide()

func _on_top_animation_finished() -> void:
	if is_dead:
		return
	if not is_outside_melee_range:
		top.play("attack")

func _on_en_hurt_box_died() -> void:
	if is_dead:
		return
	died.emit()
	is_dead = true
	top.z_index = -1
	legs.stop()
	top.stop()
	legs.hide()
	top.hide()
	
	col.set_deferred("disabled", true)
	col_shape.set_deferred("disabled", true)

	for i in range(randi_range(1, 1)):
		var b = e_die.instantiate()
		var dir_f_player = (global_position - player.global_position).normalized()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position
		b.move_dir = (global_position - player.global_position).angle()
		b.rotation = dir_f_player.angle() + deg_to_rad(90)
		b.z_index = -1
		
	for i in range(randi_range(30, 50)):
		var b = b_puddle.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		b.move_dir = (global_position - player.global_position).angle() + randf_range(-0.5, 0.5)
		b.z_index = -2
	
func _on_en_hurt_box_hurted(value: float) -> void:
	if is_dead:
		return
	for i in range(randi_range(5, 10)):
		var b = b_spread.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position
		b.move_dir = (global_position - player.global_position).angle() + randf_range(-0.5, 0.5)
		b.z_index = -2
		
	for i in range(randi_range(7, 14)):
		var b = b_fly.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position
		b.move_dir = (global_position - player.global_position).angle() + randf_range(-2.5, 2.5)
		b.z_index = -2
		
	for i in range(randi_range(10, 15)):
		var b = b_heal.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position
		b.move_dir = (player.global_position - global_position).angle() + randf_range(-1.5, 1.5)
		b.lifesteal = value / 2.0
		b.z_index = -2

func attack():
	if is_dead:
		return
	if not can_attack:
		return
	if is_reloading:
		return
	can_attack = false
	line.default_color = Color(0, 1, 0, 1)
	await get_tree().create_timer(0.25).timeout
	if is_dead:
		return
	camera.applyShake()
	top.play("attack")
	line.default_color = Color(1, 0, 0, 1)
	timer.start()
	
	current_ammo += 1
	
	var ball = projectile.instantiate()
	ball.bullet_speed = 1500
	get_tree().root.add_child(ball)
	ball.global_position = gun_point.global_position
	ball.rotation = top.rotation + deg_to_rad(-90)
	ball.damage = data.damage
	
	var predicted_velocity = player.velocity.limit_length(player.speed)
	var predicted_pos = player.global_position + predicted_velocity * 0.05
	ball.rotation = (predicted_pos - global_position).angle()

func _on_reload_time():
	is_reloading = true
	top.play("die_1")
	await get_tree().create_timer(2.2).timeout
	current_ammo = 0
	is_reloading = false

func _on_timer_timeout() -> void:
	can_attack = true
