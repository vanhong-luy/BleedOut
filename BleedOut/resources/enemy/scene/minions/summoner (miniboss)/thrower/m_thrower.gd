extends CharacterBody2D
@onready var top: AnimatedSprite2D = $top
@onready var legs: AnimatedSprite2D = $legs

@onready var en_hurt_box: en_HurtBox = $EnHurtBox


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
@onready var coli_timer: Timer = $ColiTimer



@onready var is_dead = false

var is_attack = false
var can_attack: bool = true

var stop_dis = 30

signal died

var death_list:= []

func _ready() -> void:
	en_hurt_box.en_healthpoint = data.healthpoint
	#As they thank the Lord, the blind can't see
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
		
	if player:
		var direction = (player.global_position - global_position).normalized()
		var distance = global_position.distance_to(player.global_position)
		top.rotation = direction.angle() + deg_to_rad(90)
		
		if distance <= min_dis:
			attack()
		elif distance >= max_dis:
			velocity = direction * speed
			legs.rotation = direction.angle() + deg_to_rad(90)
			legs.play("move")
		else:
			velocity = Vector2.ZERO
			legs.play("idle")
			#top.play("idle")
			attack()

	move_and_slide()

func _on_top_animation_finished() -> void:
	if is_dead:
		return
	if is_attack:
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

	#for i in range(randi_range(25, 40)):
		#var b = b_puddle.instantiate()
		#get_tree().current_scene.add_child(b)
		#b.global_position = global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		#b.move_dir = (global_position - player.global_position).angle() + randf_range(-0.5, 0.5)
		#b.z_index = -2
		
func attack():
	if not can_attack:
		return
		
	can_attack = false
	top.play("attack")
	await get_tree().create_timer(0.5).timeout
	timer.start()
	
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
