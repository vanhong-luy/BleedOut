extends CharacterBody2D
@onready var top: AnimatedSprite2D = $top
@onready var legs: AnimatedSprite2D = $legs

@onready var en_hurt_box: en_HurtBox = $EnHurtBox
@onready var camera: Camera2D = get_viewport().get_camera_2d()

#Navigation
@onready var navi_agent: NavigationAgent2D = $NavigationAgent2D
var move = false
var reached = false

#GunPoint
@onready var gun_point: Marker2D = $top/GunPoint


@onready var col:= $EnHurtBox/CollisionShape2D
@onready var en_hit_box: en_HitBox = $EnHitBox
@onready var col_shape: CollisionShape2D = $CollisionShape2D

@export var data: Enemy

@onready var player = get_tree().get_first_node_in_group("player")

var b_puddle = preload("res://resources/other/b_puddle.tscn")
var b_spread = preload("res://resources/other/b_spread.tscn")
var b_heal = preload("res://resources/other/b_heal.tscn")
var b_fly = preload("res://resources/other/b_fly.tscn")

@export var speed: float = 200
var min_dis: float = 100
var max_dis: float = 150

@export var projectile: PackedScene
@onready var timer: Timer = $Timer

@onready var shape_cast: ShapeCast2D = $top/ShapeCast

@onready var is_dead = false

var is_attack = false
var can_attack: bool = true

var is_melee = false
var stop_dis = 20

var is_range = false

#Reload
signal reload_time
var is_reloading = false
var current_ammo = 0
var max_ammo = 5

#Area2D
@onready var murica_mode: Area2D = $MuricaMode
@onready var british_mode: Area2D = $BritishMode
@onready var en_melee_range: Area2D = $en_melee_range

var is_outside_melee_range = true

signal died

var death_list:= []

func _ready() -> void:
	
	en_hit_box.damage = data.damage
	en_hurt_box.en_healthpoint = data.healthpoint
	
	#As they thank the Lord, the blind can't see
	death_list = ["die_1", "die_2", "die_3", "die_4"]
	en_hurt_box.en_healthpoint = data.healthpoint
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
		
		if is_range:
			is_melee = false
			if distance <= min_dis:
				if shape_cast.get_collider(0) == player:
					velocity = -direction * (speed / 2)
					legs.rotation = direction.angle() + deg_to_rad(90)
					legs.play("move")
					attack_range()
			elif distance >= max_dis:
				velocity = direction * speed
				legs.rotation = direction.angle() + deg_to_rad(90)
				legs.play("move")
			elif shape_cast.get_collider(0) == player:
				velocity = Vector2.ZERO
				legs.play("idle")
				#top.play("move_range")
				attack_range()
			#else:
				#velocity = direction * speed
				#legs.rotation = direction.angle() + deg_to_rad(90)
				#legs.play("move")
				#print("else being called")
		elif is_melee:
			is_range = false
			if is_attack:
				if distance > stop_dis:
					velocity = direction * speed
					legs.play("move")
				else:
					velocity = Vector2.ZERO
					legs.play("idle")
			else:
				if distance > stop_dis:
					velocity = direction * speed
					legs.rotation = direction.angle() + deg_to_rad(90)
					legs.play("move")
					top.play("move_melee")
				else:
					velocity = Vector2.ZERO
					legs.play("idle")
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
	if is_attack:
		if is_melee:
			top.play("attack_melee")
		else:
			top.play("attack_range")

func _on_en_hurt_box_died() -> void:
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

	for i in range(randi_range(25, 40)):
		var b = b_puddle.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		b.move_dir = (global_position - player.global_position).angle() + randf_range(-0.5, 0.5)
		b.z_index = -2
	
func _on_en_hurt_box_hurted(value: float) -> void:
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

func _on_murica_mode_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if is_reloading:
		return
	if body == player:
		is_melee = false
		is_range = true
		top.play("move_range")
	
func _on_murica_mode_body_exited(body: Node2D) -> void:
	if is_dead:
		return
	if is_reloading:
		return
	if body == player:
		is_melee = true
		is_range = false
		top.play("move_melee")

func attack_range():
	if is_dead:
		return
	if not can_attack:
		return
	if is_reloading:
		return
	camera.applyShake()
	top.play("attack_range")
	can_attack = false
	timer.start()
	
	var ball = projectile.instantiate()
	get_tree().root.add_child(ball)
	ball.global_position = gun_point.global_position
	ball.rotation = top.rotation + deg_to_rad(-90)
	ball.damage = 40
	
	current_ammo += 1
	
	var predicted_velocity = player.velocity.limit_length(player.speed)
	var predicted_pos = player.global_position + predicted_velocity * 0.1
	ball.rotation = (predicted_pos - global_position).angle()

func _on_reload_time():
	is_reloading = true
	top.play("die_1")
	await get_tree().create_timer(3.5).timeout
	current_ammo = 0
	is_reloading = false

#melee function
func _on_british_mode_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if is_reloading:
		return
	if body == player:
		is_melee = true
		is_range = false
		top.play("move_melee")

func _on_british_mode_body_exited(body: Node2D) -> void:
	if is_dead:
		return
	if body == player:
		is_melee = false
		is_range = true
		top.play("move_range")

func _on_top_frame_changed() -> void:
	if not top:
		return
	if top.animation == "attack_melee":
		en_hit_box.set_active(top.frame == 2)
	else:
		en_hit_box.set_active(false)

func _on_en_melee_range_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if is_reloading:
		return
	
	if body != player:
		return
	is_outside_melee_range = false
	is_attack = true
	en_melee_range.set_deferred("monitoring", false)
	#top.flip_h = false
	#combo = 1
	top.play("attack_melee")

func _on_en_melee_range_body_exited(body: Node2D) -> void:
	if body != player:
		return
	is_outside_melee_range = true
	is_attack = false
	en_melee_range.set_deferred("monitoring", true)

func _on_timer_timeout() -> void:
	can_attack = true
