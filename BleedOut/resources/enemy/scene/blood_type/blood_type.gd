extends CharacterBody2D
@onready var top: AnimatedSprite2D = $top
@onready var legs: AnimatedSprite2D = $legs

@onready var en_hit_box: en_HitBox = $EnHitBox
@onready var en_hurt_box: en_HurtBox = $EnHurtBox

#Navigation
@onready var navi_agent: NavigationAgent2D = $NavigationAgent2D
var move = false
var reached = false

@onready var prep_time: Timer = $PrepTime
var is_ready = false

#Abilities
var can_shockwave = true
var is_shockwave = false
@export var projectile: PackedScene
@onready var sw_timer: Timer = $SWTimer

#Charge
@onready var charge_push: Area2D = $ChargePush
var charge
var charge_direction: Vector2
var can_charge = true
var is_charging = false
var charge_launch_force = 1000
@export var charge_speed: float = 800
@export var charge_cooldown: float = 2.5

#Stomp
var is_in_stomp_zone = false
var can_stomp = true
var is_stomp = false
var stomp_launch_force = 500
@onready var stomp_zone: Area2D = $StompZone
@onready var stomping: Area2D = $Stomping
var stomp_cooldown: float = 2.5 #just a display
@onready var stomp_timer: Timer = $StompTimer


@onready var col:= $EnHurtBox/CollisionShape2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var en_melee_range: Area2D = $en_melee_range

@export var data: Enemy

@onready var player = get_tree().get_first_node_in_group("player")

var b_puddle = preload("res://resources/other/b_puddle.tscn")
var b_spread = preload("res://resources/other/b_spread.tscn")
var b_fly = preload("res://resources/other/b_fly.tscn")
var b_heal = preload("res://resources/other/b_heal.tscn")


@export var speed: float = 100
var stop_dis = 20

@onready var is_dead = false

signal died

var is_attack = false
var is_outside_melee_range = true

var death_list:= []

func _ready() -> void:
	charge_push.set_deferred("monitoring", false)
	
	en_hit_box.damage = data.damage
	en_hurt_box.en_healthpoint = data.healthpoint
	
	#My blood type mark is on the sleeve

	death_list = ["die_1", "die_2", "die_3", "die_4"]

	prep_time.start()
func _physics_process(_delta):
	if is_dead:
		return
		
	if not player:
		return

	if player.is_dead:
		top.play("idle")
		legs.play("idle")
		return
		
	if is_charging:
		move_and_slide()
		return
	
	navigation()
	navigating()
	if player:
		var next_pos = navi_agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		var distance = global_position.distance_to(player.global_position)
		top.rotation = direction.angle() + deg_to_rad(90)
		
		if can_charge and is_ready and not is_in_stomp_zone and not is_charging and distance > 25 and distance < 200:
			charging()
			return
		if can_shockwave and is_ready and not is_in_stomp_zone and not is_charging and not is_attack:
			shockwave_attack()
			return
		
		if is_charging:
			velocity = direction * charge_speed
		
		if is_attack:
			if distance > stop_dis:
				velocity = direction * speed
				legs.play("move")
			else:
				velocity = Vector2.ZERO
				legs.play("idle")
		else:
			if is_shockwave:
				velocity = Vector2.ZERO
				legs.play("idle")
			elif distance > stop_dis:
				velocity = direction * speed
				legs.rotation = direction.angle() + deg_to_rad(90)
				legs.play("move")
				if not is_charging and not is_shockwave:
					top.play("move")
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

func _on_en_melee_range_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	
	if body != player:
		return
	is_outside_melee_range = false
	is_attack = true
	en_melee_range.set_deferred("monitoring", false)
	#top.flip_h = false
	#combo = 1
	top.play("attack")

func _on_en_melee_range_body_exited(body: Node2D) -> void:
	if body != player:
		return
	is_outside_melee_range = true
	is_attack = false
	en_melee_range.set_deferred("monitoring", true)

func _on_top_animation_finished() -> void:
	if is_dead:
		return
	if is_shockwave:
		return
	if not is_outside_melee_range or is_attack:
		top.play("attack")
	else:
		en_melee_range.set_deferred("monitoring", true)

#problem: make it has cooldown, currently it spamming
#solved: not really, i just extend the anim, give the look that it has cooldown. there should be another way to do it
func _on_top_frame_changed() -> void:
	if not top:
		return
	if top.animation == "attack":
		en_hit_box.set_active(top.frame == 2)
	else:
		en_hit_box.set_active(false)

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
	en_hit_box.set_deferred("disabled", true)

	#for i in range(randi_range(5, 10)):
		#var b = b_spread.instantiate()
		#get_tree().current_scene.add_child(b)
		#b.global_position = global_position
		#b.move_dir = (global_position - player.global_position).angle() + randf_range(-0.5, 0.5)
		#b.z_index = -2
	
	for i in range(randi_range(15, 25)):
		var b = b_puddle.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		b.move_dir = (global_position - player.global_position).angle() + randf_range(-0.5, 0.5)
		b.z_index = -2

func _on_en_hurt_box_hurted(value: float) -> void:
		
	if is_dead:
		return
		
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

func charging() -> void:
	
	if not is_ready:
		top.play("idle")
		return
	
	if is_shockwave:
		return
	
	is_charging = true
	can_charge = false
	velocity = Vector2.ZERO

	#giddy up: keep rotating toward player for 0.5s
	var wind_up_time = 0.5
	var elapsed = 0.0
	while elapsed < wind_up_time:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if player and not player.is_dead:
			var predicted_velocity = player.velocity.limit_length(player.speed)
			var charge_target = player.global_position + predicted_velocity * randf_range(0.1, 0.3)
			charge_direction = (charge_target - global_position).normalized()
			top.rotation = charge_direction.angle() + deg_to_rad(90)

	# Commit and launch
	charge_push.set_deferred("monitoring", true)
	velocity = charge_direction * charge_speed
	await get_tree().create_timer(0.5).timeout

	charge_push.set_deferred("monitoring", false)
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.1).timeout
	is_charging = false

	await get_tree().create_timer(charge_cooldown).timeout
	can_charge = true

func _on_charge_push_body_entered(body: Node2D) -> void:
	if body == self:
		return
	#if is_in_stomp_zone:
		#return
	if body == player:
		player.apply_knockback(charge_direction * charge_launch_force)
		player.hurt_box.get_damage(data.damage, global_position)
		

func _on_stomping_body_entered(body: Node2D) -> void:
	if body != player:
		return
	if is_dead:
		return
	is_in_stomp_zone = true
	stomp_timer.start()

func _on_stomping_body_exited(body: Node2D) -> void:
	if body != player:
		return
	if is_dead:
		return
	is_in_stomp_zone = false
	stomp_timer.stop()

func _on_stomp_timer_timeout() -> void:
	if is_dead:
		return
	if not is_in_stomp_zone:
		return
	can_stomp = false
	#print("you, im being called")
	var stomp_direction = (player.global_position - global_position).normalized()
	player.apply_knockback(stomp_direction * stomp_launch_force)
	player.hurt_box.get_damage(data.damage, global_position)
	can_stomp = true

func shockwave_attack() -> void:
	
	if is_charging:
		return
	
	if not is_ready:
		top.play("idle")
		return
	
	can_shockwave = false
	is_shockwave = true
	velocity = Vector2.ZERO
	top.play("shockwave_aim")
	sw_timer.start()
	
	await get_tree().create_timer(0.5).timeout
	top.play("shockwave")
	
	var ball = projectile.instantiate()
	get_tree().root.add_child(ball)
	ball.global_position = global_position
	ball.rotation = top.rotation + deg_to_rad(-90)
	ball.damage = data.damage
	
	var predicted_velocity = player.velocity.limit_length(player.speed)
	var predicted_pos = player.global_position + predicted_velocity * 0.2
	ball.rotation = (predicted_pos - global_position).angle()
	
	await get_tree().create_timer(0.5).timeout
	top.play("idle")
	await top.animation_finished
	is_shockwave = false
	
func _on_sw_timer_timeout() -> void:
	can_shockwave = true


func _on_prep_time_timeout() -> void:
	is_ready = true
