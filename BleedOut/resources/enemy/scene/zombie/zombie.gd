extends CharacterBody2D
@onready var top: AnimatedSprite2D = $top
@onready var legs: AnimatedSprite2D = $legs

@onready var en_hit_box: en_HitBox = $EnHitBox
@onready var en_hurt_box: en_HurtBox = $EnHurtBox

#Navigation
@onready var navi_agent: NavigationAgent2D = $NavigationAgent2D
var move = false
var reached = false

@onready var col:= $EnHurtBox/CollisionShape2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var en_melee_range: Area2D = $en_melee_range

@export var data: Enemy

@onready var player = get_tree().get_first_node_in_group("player")

var b_puddle = preload("res://resources/other/b_puddle.tscn")
var b_spread = preload("res://resources/other/b_spread.tscn")
var b_fly = preload("res://resources/other/b_fly.tscn")
var b_heal = preload("res://resources/other/b_heal.tscn")
var e_die = preload("res://resources/enemy/death/zombie_die.tscn")


@export var speed: float = 150
var stop_dis = 20

@onready var is_dead = false

signal died

var is_attack = false
var is_outside_melee_range = true

#problem: need to make a bunch of death pose, then stuff em in here, then randomize enemy death pose
#solved: down there :D
var death_list:= []

func _ready() -> void:
	#print(data.name,"'s Score: ",data.score)
	
	en_hit_box.damage = data.damage
	en_hurt_box.en_healthpoint = data.healthpoint
	
	#Darkness falls across the land

	death_list = ["die", "die_2", "die_3", "die_4"]

func _physics_process(_delta):
	if is_dead:
		return
		
	if not player:
		return

	if player.is_dead:
		top.play("idle")
		legs.play("idle")
		return
		
		
	navigation()
	navigating()
	if player:
		var next_pos = navi_agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		var distance = global_position.distance_to(player.global_position)
		top.rotation = direction.angle() + deg_to_rad(90)
		
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
	if is_dead:
		return
	died.emit()
	is_dead = true
	player.total_score += data.score
	velocity = Vector2.ZERO
	top.z_index = -1
	legs.stop()
	top.stop()
	legs.hide()
	top.hide()
	#top.offset.y += 20
	#top.flip_v = true
	
	col.set_deferred("disabled", true)
	col_shape.set_deferred("disabled", true)
	en_hit_box.set_deferred("disabled", true)

	for i in range(randi_range(1, 1)):
		var b = e_die.instantiate()
		var dir_f_player = (global_position - player.global_position).normalized()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position
		b.move_dir = (global_position - player.global_position).angle()
		b.rotation = dir_f_player.angle() + deg_to_rad(90)
		b.z_index = -1
	
	for i in range(randi_range(5, 10)):
		var b = b_puddle.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		b.move_dir = (global_position - player.global_position).angle() + randf_range(-0.5, 0.5)
		b.z_index = -2

func _on_en_hurt_box_hurted(value: float) -> void:
	if is_dead:
		return
	#for i in range(randi_range(5, 10)):
		#var b = b_spread.instantiate()
		#get_tree().current_scene.add_child(b)
		#b.global_position = global_position
		#b.move_dir = (global_position - player.global_position).angle() + randf_range(-0.5, 0.5)
		#b.z_index = -2
		
	for i in range(randi_range(5, 10)):
		var b = b_fly.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position
		b.move_dir = (global_position - player.global_position).angle() + randf_range(-2.5, 2.5)
		b.z_index = -2
	
		
	for i in range(randi_range(5, 10)):
		var b = b_heal.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position
		b.move_dir = (player.global_position - global_position).angle() + randf_range(-1.5, 1.5)
		b.lifesteal = value / 2.0
		b.z_index = -2
