extends CharacterBody2D
@onready var top: AnimatedSprite2D = $top
@onready var legs: AnimatedSprite2D = $legs

@onready var en_hurt_box: en_HurtBox = $EnHurtBox

#Navigation
@onready var navi_agent: NavigationAgent2D = $NavigationAgent2D
var move = false
var reached = false

#raycasting
@onready var ray_cast: RayCast2D = $top/RayCast


@onready var col:= $EnHurtBox/CollisionShape2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D

@export var data: Enemy

@onready var player = get_tree().get_first_node_in_group("player")

var b_puddle = preload("res://resources/other/b_puddle.tscn")
var b_spread = preload("res://resources/other/b_spread.tscn")
var b_heal = preload("res://resources/other/b_heal.tscn")
var b_fly = preload("res://resources/other/b_fly.tscn")

@export var speed: float = 150
var min_dis: float = 100
var max_dis: float = 200

@export var projectile: PackedScene
@onready var timer: Timer = $Timer


@onready var is_dead = false

var is_attack = false
var can_attack: bool = true

var stop_dis = 30

signal died

var death_list:= []

func _ready() -> void:
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
		
	navigation()
	navigating()
		
	if player:
		var next_pos = navi_agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		var distance = global_position.distance_to(player.global_position)
		top.rotation = direction.angle() + deg_to_rad(90)
		
		if distance <= min_dis:
			if ray_cast.is_colliding() and ray_cast.get_collider() == player:
				attack()
		elif distance >= max_dis:
			velocity = direction * speed
			legs.rotation = direction.angle() + deg_to_rad(90)
			legs.play("move")
		elif ray_cast.is_colliding() and ray_cast.get_collider() == player:
			velocity = Vector2.ZERO
			legs.play("idle")
			#top.play("idle")
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
	if is_attack:
		top.play("attack")

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
	if not can_attack:
		return
	top.play("attack")
	can_attack = false
	timer.start()
	
	await get_tree().create_timer(0.5).timeout
	
	var ball = projectile.instantiate()
	get_tree().root.add_child(ball)
	ball.global_position = global_position
	ball.rotation = top.rotation + deg_to_rad(-90)
	ball.damage = data.damage
	
	var predicted_velocity = player.velocity.limit_length(player.speed)
	var predicted_pos = player.global_position + predicted_velocity * 0.1
	ball.rotation = (predicted_pos - global_position).angle()

	
func _on_timer_timeout() -> void:
	can_attack = true
