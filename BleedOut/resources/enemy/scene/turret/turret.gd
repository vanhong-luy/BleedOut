extends CharacterBody2D
@onready var top: AnimatedSprite2D = $top
@onready var legs: AnimatedSprite2D = $legs

@onready var en_hurt_box: en_HurtBox = $EnHurtBox

#Shapecasting
@onready var shape_cast: ShapeCast2D = $top/ShapeCast

#Camera
@onready var camera: Camera2D = get_viewport().get_camera_2d()

#Reload
var current_ammo = 0
var max_ammo = 50
var is_reloading = false
signal reload_time

#Gunpoint
@onready var gun_point: Marker2D = $top/GunPoint


@onready var col:= $EnHurtBox/CollisionShape2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D

@export var data: Enemy

@onready var player = get_tree().get_first_node_in_group("player")

@export var projectile: PackedScene
@onready var timer: Timer = $Timer

@onready var is_dead = false

var is_attack = false
var can_attack: bool = true


signal died

func _ready() -> void:
	en_hurt_box.en_healthpoint = data.healthpoint
	
	#Gruppa krovi na rukave
	
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
		
	if player:
		var direction = (player.global_position - global_position).normalized()
		top.rotation = direction.angle() + deg_to_rad(90)
		
		if shape_cast.is_colliding() and shape_cast.get_collider(0) == player:
			attack()
		else:
			top.play("idle")

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
	#top.z_index = -1
	legs.play("die")
	top.play("die")
	
	col.set_deferred("disabled", true)
	col_shape.set_deferred("disabled", true)

	#no blood drop

func attack():
	if not can_attack:
		return
	if is_reloading:
		return
	camera.applyShake()
	top.play("attack")
	can_attack = false
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
	top.play("die") #same sprite as reload
	await get_tree().create_timer(2.2).timeout
	current_ammo = 0
	is_reloading = false

func _on_timer_timeout() -> void:
	can_attack = true
