extends CharacterBody2D
@onready var top: AnimatedSprite2D = $top
@onready var legs: AnimatedSprite2D = $legs

@onready var en_hurt_box: en_HurtBox = $EnHurtBox

#Navigation
@onready var navi_agent: NavigationAgent2D = $NaviAgent
var move = false
var reached = false

#Shapecasting
@onready var shape_cast: ShapeCast2D = $top/ShapeCast

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
		return
	if player.is_dead:
		top.play("idle")
		legs.play("idle")
		return
		
	if current_ammo == max_ammo and not is_reloading:
		reload_time.emit()
		
	navigation()
	navigating()
	if player:
		var next_pos = navi_agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		var distance = global_position.distance_to(player.global_position)
		top.rotation = direction.angle() + deg_to_rad(90)
		
		if distance <= min_dis:
			if shape_cast.is_colliding() and shape_cast.get_collider(0) == player:
				velocity = -direction * (speed / 2)
				legs.rotation = direction.angle() + deg_to_rad(90)
				legs.play("move")
				#print("i am first if")
				attack()
		elif distance >= max_dis:
			velocity = direction * speed
			legs.rotation = direction.angle() + deg_to_rad(90)
			legs.play("move")
			#print("i am second if")
		elif shape_cast.is_colliding() and shape_cast.get_collider(0) == player:
			velocity = Vector2.ZERO
			legs.play("idle")
			#print("i am third if")
			#top.play("move_range")
			attack()

	move_and_slide()

func navigation():
	navi_agent.target_position = player.global_position
	move = true
	reached = false
func navigating():
	if navi_agent.is_navigation_finished():
		move = false
		reached = true
		navi_agent.velocity = Vector2.ZERO
		return

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
	velocity = Vector2.ZERO
	top.play(death_list.pick_random())
	top.z_index = -1
	legs.stop()
	top.offset.y += 20
	top.flip_v = true
	
	col.set_deferred("disabled", true)
	col_shape.set_deferred("disabled", true)

	#for i in range(randi_range(20, 25)):
		#var b = b_spread.instantiate()
		#get_tree().current_scene.add_child(b)
		#b.global_position = global_position
		#b.move_dir = (global_position - player.global_position).angle() + randf_range(-0.5, 0.5)
		#b.z_index = -2
		
	for i in range(randi_range(30, 50)):
		var b = b_puddle.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		b.move_dir = (global_position - player.global_position).angle() + randf_range(-0.5, 0.5)
		b.z_index = -2
		
	#for i in range(randi_range(10, 15)):
		#var b = b_heal.instantiate()
		#get_tree().current_scene.call_deferred("add_child", b)
		#b.global_position = global_position
		#b.move_dir = (player.global_position - global_position).angle() + randf_range(-0.3, 0.3)
		#b.lifesteal = value
		#b.z_index = -1
	
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
	await get_tree().create_timer(0.25).timeout
	if is_dead:
		return
	camera.applyShake()
	top.play("attack")
	timer.start()
	
	current_ammo += 1
	
	var ball = projectile.instantiate()
	get_tree().root.add_child(ball)
	ball.global_position = gun_point.global_position
	ball.rotation = top.rotation + deg_to_rad(-90)
	ball.damage = data.damage
	
	var predicted_velocity = player.velocity.limit_length(player.speed)
	var predicted_pos = player.global_position + predicted_velocity * 0.1
	ball.rotation = (predicted_pos - global_position).angle()

func _on_reload_time():
	is_reloading = true
	top.play("die_1")
	await get_tree().create_timer(2.2).timeout
	current_ammo = 0
	is_reloading = false

func _on_timer_timeout() -> void:
	can_attack = true
