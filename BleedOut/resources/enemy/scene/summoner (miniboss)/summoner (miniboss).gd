extends CharacterBody2D
@onready var top: AnimatedSprite2D = $top
@onready var legs: AnimatedSprite2D = $legs

@onready var en_hurt_box: en_HurtBox = $EnHurtBox
@onready var minion_spawn = $MinionSpawn.get_children()


@onready var col:= $EnHurtBox/CollisionShape2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var summon_cooldown: Timer = $SummonCooldown


@export var data: Enemy

@onready var player = get_tree().get_first_node_in_group("player")

var b_puddle = preload("res://resources/other/b_puddle.tscn")
var b_spread = preload("res://resources/other/b_spread.tscn")
var b_heal = preload("res://resources/other/b_heal.tscn")
var b_fly = preload("res://resources/other/b_fly.tscn")


var spawn_warning = preload("res://resources/level/other/spawn_warning.tscn")

@export var speed: float = 150
var min_dis: float = 100
var max_dis: float = 200

@export var projectile: PackedScene
@onready var timer: Timer = $Timer

@onready var is_dead = false

var is_attack = false
var can_attack: bool = true

var is_outside_melee_range = true
var stop_dis = 30

var max_minion = 4
var current_minion = 0

var en_1 = preload("res://resources/enemy/scene/minions/summoner (miniboss)/zombie/m_zombie.tscn")
var en_2 = preload("res://resources/enemy/scene/minions/summoner (miniboss)/thrower/m_thrower.tscn")

var enemy: Array[PackedScene] = [en_1, en_2]


signal died

var death_list:= []

func _ready() -> void:
	
	en_hurt_box.en_healthpoint = data.healthpoint
	can_attack = false
	await get_tree().create_timer(1.5).timeout
	can_attack = true
	
	#You've got another thing comin'
	death_list = ["die_1", "die_2"]
	
	summon_cooldown.timeout.connect(summon)
	summon_cooldown.start()

func _physics_process(_delta):
	if is_dead:
		return
	if player.is_dead:
		top.play("idle")
		legs.play("idle")
		return
		
	$MinionSpawn.rotation = top.rotation
	
	if player:
		var direction = (player.global_position - global_position).normalized()
		var distance = global_position.distance_to(player.global_position)
		top.rotation = direction.angle() + deg_to_rad(90)
		
		if distance <= min_dis:
			if distance <= stop_dis:
				velocity = Vector2.ZERO
				legs.play("idle")
			else:
				velocity = -direction * (speed / 2)
				legs.rotation = direction.angle() + deg_to_rad(90)
				legs.play("move")
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
	can_attack = false
	top.play("attack")
	await get_tree().create_timer(0.35).timeout
	if is_dead:
		return
	timer.start()

	
	var ball = projectile.instantiate()
	get_tree().root.add_child(ball)
	ball.global_position = global_position
	ball.rotation = top.rotation + deg_to_rad(-90)
	ball.damage = data.damage
	
	var predicted_velocity = player.velocity.limit_length(player.speed)
	var predicted_pos = player.global_position + predicted_velocity * 0.1
	ball.rotation = (predicted_pos - global_position).angle()

func summon():
	
	if is_dead:
		return
	
	if current_minion >= max_minion:
		return
		
	var warnings = Warning()
	await get_tree().create_timer(0.5).timeout
	
	for w in warnings:
		w.queue_free()
	
	var room = get_parent()
	
	for p in minion_spawn:
		if current_minion >= max_minion:
			break
		var e = spawn_bias().instantiate()
		get_tree().current_scene.add_child(e)  # add to scene, not summoner
		e.global_position = p.global_position
		current_minion += 1
		e.died.connect(on_minion_died)
		
		if room.has_method("register_enemy"):
				room.register_enemy(e)

func spawn_bias():
	var chance = [70, 30]
	var total = chance.reduce(func(a, b): return a + b)
	var roll = randi_range(0, total - 1)
	
	var sum = 0
	for i in range(enemy.size()):
		sum += chance[i]
		if roll < sum:
			return enemy[i]

func on_minion_died():
	current_minion -= 1
	
func Warning():
	var warnings = []
	var warn_spot = 0
	for p in minion_spawn:
		if current_minion + warn_spot >= max_minion:
			break
		warn_spot += 1

		var warning = spawn_warning.instantiate()
		get_tree().current_scene.add_child(warning)
		warning.global_position =p.global_position
		warning.z_index = 2
		warnings.append(warning)
	return warnings

func _on_timer_timeout() -> void:
	can_attack = true
