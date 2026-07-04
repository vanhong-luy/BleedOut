extends CharacterBody2D
@onready var top: AnimatedSprite2D = $top
@onready var legs: AnimatedSprite2D = $legs

@onready var en_hit_box: en_HitBox = $EnHitBox
@onready var en_hurt_box: en_HurtBox = $EnHurtBox


@onready var col:= $EnHurtBox/CollisionShape2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var en_melee_range: Area2D = $en_melee_range
@onready var charge_push: Area2D = $ChargePush

@export var data: Enemy

@onready var player = get_tree().get_first_node_in_group("player")

var b_puddle = preload("res://resources/other/b_puddle.tscn")
var b_spread = preload("res://resources/other/b_spread.tscn")
var b_heal = preload("res://resources/other/b_heal.tscn")
var b_fly = preload("res://resources/other/b_fly.tscn")

@export var speed: float = 175
@onready var is_dead = false

signal died

var is_attack = false
var is_outside_melee_range = true
var stop_dis = 30

@export var charge_speed: float = 800
@export var charge_cooldown: float = 2.5 #maybe try using Timer instead? No, i think it's fine this way


var charge_direction: Vector2
var can_charge = true
var is_charging = false
var launch_force = 1000


var death_list:= []

func _ready() -> void:
	
	charge_push.set_deferred("monitoring", false)
	
	en_hit_box.damage = data.damage
	en_hurt_box.en_healthpoint = data.healthpoint
	
	#print("Start Health:",data.healthpoint)
	#Die, by my hand, I creep across the land, kill the firstborn man
	#top.animation = "die_1"
	#top.animation = "die_2"
	#top.animation = "die_3"
	#top.animation = "die_4"

	death_list = ["die_1", "die_2", "die_3", "die_4"]

func _physics_process(_delta):
	if is_dead:
		return
	if player.is_dead:
		top.play("idle")
		legs.play("idle")
		return
	if is_charging:
		move_and_slide()
		return
		
	if player:
		var direction = (player.global_position - global_position).normalized()
		var distance = global_position.distance_to(player.global_position)
		top.rotation = direction.angle() + deg_to_rad(90)
		
		if can_charge and not is_charging and distance > 25 and distance < 200:
			charging()
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
			velocity = direction * speed
			legs.rotation = direction.angle() + deg_to_rad(90)
			legs.play("move")
			top.play("move")
	move_and_slide()

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
	if not is_outside_melee_range:
		#combo = 2 if combo == 1 else 1
		#top.flip_h = combo == 2
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

	for i in range(randi_range(25, 40)):
		var b = b_puddle.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		b.move_dir = (global_position - player.global_position).angle() + randf_range(-0.5, 0.5)
		b.z_index = -2

	for i in range(randi_range(10, 15)):
		var b = b_spread.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position
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
			var charge_target = player.global_position + predicted_velocity * 0.3
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
	
	#print("charge_direction: ", charge_direction)
	#print("is_charging: ", is_charging)
	#print("hit: ", body.name)
	if body == player:
		player.apply_knockback(charge_direction * launch_force)
		player.hurt_box.get_damage(data.damage, global_position)
