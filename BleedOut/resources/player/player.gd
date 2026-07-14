extends CharacterBody2D

@export var speed: float = 200

@onready var legs = $legs
@onready var top = $top

@onready var blunt_hand: Node2D = $top/BluntHand
@onready var sharp_hand: Node2D = $top/SharpHand
@onready var pistol_hand: Node2D = $top/PistolHand
@onready var second_hand: Node2D = $top/SecondHand


@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var hurt_box: HurtBox = $HurtBox
@onready var camera: Camera2D = get_viewport().get_camera_2d()

#@onready var katana_fx: Sprite2D = $Node2D/KatanaFX


@onready var melee_anim: AnimationPlayer = $Node2D/MeleeAnim
@onready var pistol_anim: AnimationPlayer = $Node2D/PistolAnim

@onready var swing_fx: Node2D = $Node2D
@onready var hit_box: HitBox = $HitBox
@onready var hb_box: CollisionShape2D = $HitBox/CollisionShape2D #not homeboy box

#Freeze
var is_freeze: bool = false

#Death Screen
@onready var death_screen: CanvasLayer = $"Death Screen"


var dash_speed = 500
var sprint_speed: float = 1.5
var dashing = false
var dash_amount = 3
var max_dash = 3
var can_dash = true
var recharging = false

var melee_pos_right = Vector2(5, -3)
var melee_pos_left = Vector2(-5, -3)
var melee_on_right = true
var melee_id = 0
var current_top_anim = ""

var can_melee:= true
var max_swing = 3
var swing_amount = 3
var recovering = false
var combo_step = 1
var is_holding_melee = false

var knockback = Vector2.ZERO

var pistol_pos = Vector2(4, -18)
var can_shoot:= true
var is_holding_pistol = false
var is_reloading = false

var second_pos = Vector2(2, 5)
var is_holding_second = false

var max_health = 100
var health: float = 100
var invincible = false #[TITLE CARD]
var is_dead = false

#Trans
var trans_cooldown: float = 0.5
var trans_timer: float = 0.0

@onready var panel: CanvasLayer = $Panel
@onready var health_bar: ProgressBar = $Panel/HealthBar


#score
var total_score = 0

#m0nesy
var total_money = 0

@export var weapon_list: Array[WeaponData] = []  # drag .tres files here. No not here, in Inspector
var weapons = []
var current_weapon = 0

var b_puddle = preload("res://resources/other/b_puddle.tscn")
var b_spread = preload("res://resources/other/b_spread.tscn")
var b_fly = preload("res://resources/other/b_fly.tscn")
var p_die = preload("res://resources/player/scenes/p_die.tscn")

const ENEMY_LAYER = 0

func _ready() -> void:
	death_screen.hide()
	death_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	health_bar.init_health(health)
	if GameState.saved_data != null:
		if !GameState.saved_data.is_empty():
			weapon_list = GameState.saved_data.weapon_list
	if GameState.player_node != null and is_instance_valid(GameState.player_node) and GameState.player_node != self:
		queue_free()
		return
	GameState.player_node = self
	
	for data in weapon_list:
		var node = data.scene.instantiate()
		# Choose which hand to parent to
		var target_hand
		if data.type == WeaponData.Type.pistol:
			target_hand = pistol_hand
		elif data.type == WeaponData.Type.second:
			target_hand = second_hand
		elif data.type == WeaponData.Type.melee_sharp:
			target_hand = sharp_hand
		else:
			target_hand = blunt_hand
		
		target_hand.add_child(node)
		node.hide()
		weapons.append(
			{
				"name": data.name,
				"damage": data.damage, 
				"node": node, 
				"type": data.type,
				"mag_cap": data.mag_cap, #amount of bullet in a round
				"max_mag": data.max_mag, #total amount of bullet in a round
				"spare_ammo": data.spare_ammo, #some extra ammo
				"max_spare": data.max_spare, #amount of extra a gun can hold
				"fire_rate": data.fire_rate
				}
			)
	
	if weapons.is_empty():
		print("No weapons! Drag .tres files into weapon_list in Inspector")
		return
	
	if GameState.saved_data != null:
		var d = GameState.saved_data
		if !GameState.saved_data.is_empty():
			health = d.health
			hurt_box.healthpoint = health
			current_weapon = d.current_weapon
		for i in range(weapons.size()):
			if !GameState.saved_data.is_empty():
				weapons[i].mag_cap = d.ammo[i].mag_cap
				weapons[i].spare_ammo = d.ammo[i].spare_ammo
		
	var spawn = get_tree().get_first_node_in_group("PlayerSpawn")
	if spawn:
		global_position = spawn.global_position
	
	_update_holding_state()
		
	weapons[current_weapon].node.show()
	hit_box.damage = weapons[current_weapon].damage

func _input(event):
	if event.is_action_pressed("weapon_next"):
		switch_weapon_next()
	if event.is_action_pressed("weapon_prev"):
		switch_weapon_prev()

func _physics_process(_delta):
	if is_dead:
		if Input.is_action_just_pressed("reload"):
			GameState.player_node = null
			get_tree().reload_current_scene()
		return
	
	var direction = Vector2.ZERO
	
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	direction = direction.normalized()
	
	knockback = knockback.lerp(Vector2.ZERO, 0.05)
	
	if dashing:
		velocity = direction * dash_speed
	elif Input.is_action_pressed("sprint"):
		velocity = direction * speed * sprint_speed
	else:
		velocity = direction * speed
		
	velocity += knockback
	move_and_slide()
	
	# Legs
	if direction.length() > 0:
		legs.rotation = direction.angle() + deg_to_rad(90)
		legs.play("move")
	else:
		legs.play("idle")

	# Top only animates normally if not attacking. after some times, i have no idea what im talking about
	if can_melee:
		if is_holding_melee:
			if weapons[current_weapon].type == WeaponData.Type.melee_sharp:
				top.play("sharp_idle")
			else:
				top.play("idle_melee")
		elif is_holding_pistol:
			#print("is_reloading: ", is_reloading)
			if is_reloading:
				top.play("pistol_reload")
			else:
				top.play("pistol")
		elif is_holding_second:
			if is_reloading:
				top.play("pistol_reload")
			else:
				top.play("second")
		else:
			if direction.length() > 0:
				top.play("move")
			else:
				top.play("idle")
				
	if is_reloading:
		pistol_anim.play("pistol_reload")
		
	#if Input.is_action_pressed("trans") and health > 20:
		##trans = transfer btw
		#trans_timer -= _delta
		#var weapon = weapons[current_weapon]
		#if weapon.type == WeaponData.Type.pistol and weapon.spare_ammo < weapon.max_spare and trans_timer <= 0:
			#health -= 5
			#weapons[current_weapon].spare_ammo += 1
			#trans_timer = trans_cooldown
		#elif weapon.type == WeaponData.Type.second and weapon.spare_ammo < weapon.max_spare and trans_timer <= 0:
			#health -= 10
			#weapons[current_weapon].spare_ammo += 1
			#trans_timer = trans_cooldown
	
	#if Input.is_action_just_pressed("trans"):
		#print("Total Score: ", total_score)
	
	if Input.is_action_just_pressed("attack") and can_melee and swing_amount > 0:
		
		if is_holding_melee:
			swing_amount -= 1
			melee()
			if not recovering:
				recovering = true
				swing_recover()
		#elif is_holding_pistol and can_shoot:
			#pistolShoot()
			#await get_tree().create_timer(weapons[current_weapon].fire_rate).timeout
		
	# call reload from physics process
	if Input.is_action_just_pressed("reload") and is_holding_pistol and !is_reloading:
		#print("reload pressed")
		reload()
		
	if Input.is_action_just_pressed("interact"):
		interact()
	if Input.is_action_just_pressed("dash") and dash_amount > 0 and can_dash:
		if velocity == Vector2.ZERO:
			return
		dash_amount -= 1
		dash()
		if not recharging:
			recharging = true
			recharge_dash()
func _process(_delta):
	
	if is_dead:
		return
	
	var mouse_pos = get_global_mouse_position()
	var direction = mouse_pos - global_position
	
	top.rotation = direction.angle() + deg_to_rad(90)
	swing_fx.rotation = direction.angle() + deg_to_rad(90)
	
	
#problem: need to delete Hand Node when player dies, so the weapon doesn't float when player die
#solved: btw, it's not here. it's up there, somewhere, hide hand' nodes
func melee():
	if !is_holding_melee:
		return
	var t = weapons[current_weapon].type
	if t == WeaponData.Type.melee_blunt:
		meleeBlunt()
	elif t == WeaponData.Type.melee_sharp:
		meleeSharp()

func meleeBlunt():
	can_melee = false
	melee_id += 1
	var my_id = melee_id

	if combo_step == 1:
		melee_anim.play("melee_atk_1")
		combo_step = 2
	elif combo_step == 2:
		melee_anim.play("melee_atk_2")
		combo_step = 1
	top.play("melee_atk")

	await get_tree().create_timer(0.2).timeout

	if my_id != melee_id:
		return

	melee_on_right = !melee_on_right
	blunt_hand.position = melee_pos_right if melee_on_right else melee_pos_left
	top.flip_h = !melee_on_right
	can_melee = true
	top.stop()

func meleeSharp():
	can_melee = false
	melee_id += 1
	var my_id = melee_id
	
	if weapons[current_weapon].name == "katana":
		melee_anim.play("sharp_atk")
		top.play("sharp_atk")
	else:
		melee_anim.play("sharp_atk_alt")
		top.play("sharp_atk_alt")
	await get_tree().create_timer(0.5).timeout
	if my_id != melee_id:
		return
	can_melee = true
	top.stop()

func heal(lifesteal: float):
	if is_dead:
		return
	health = min(health + lifesteal, max_health)
	hurt_box.healthpoint = health
	health_bar.health = health

#moved to gun instead
#func pistolShoot():
	#
	#if !is_holding_pistol:
		#return
	#
	#if weapons[current_weapon].mag_cap <= 0:
		#print("I'm empty")
		#return
	#
	#if !weapons[current_weapon].name == "g_18":
		#camera.applyShake()
	#can_shoot = false
	#
	#weapons[current_weapon].mag_cap -= 1
	#pistol_anim.play("attack")
	#top.play("pistol")
	##await get_tree().create_timer(weapons[current_weapon].fire_rate).timeout
	#can_shoot = true
	#
	#print("Current Ammo:", weapons[current_weapon].mag_cap)
	#
	##if weapons[current_weapon].mag_cap == 0:
		##print("reloading")
		##reload()
	#print("Spare Ammo:", weapons[current_weapon].spare_ammo)
	##await get_tree().create_timer(1).timeout

func reload():
	if is_reloading:
		return
	var w = weapons[current_weapon]
	if w.spare_ammo <= 0 or w.mag_cap == w.max_mag:
		return
	
	is_reloading = true
	can_shoot = false
	# anim plays in _physics_process via is_reloading check, no need to call here
	
	#top.play("pistol_reload")      # play top anim once
	#pistol_anim.play("pistol_reload")  # play hand anim once
	#
	#await pistol_anim.animation_finished
	
	#pistol_anim.play("pistol_reload")
	#print("im being called")
	await get_tree().create_timer(0.8).timeout  # actual reload time, yea i know, all guns are the same
	
	var needed = w.max_mag - w.mag_cap
	var available = w.spare_ammo
	
	if available >= needed:
		w.spare_ammo -= needed
		w.mag_cap = w.max_mag
	else:
		w.mag_cap += available
		w.spare_ammo = 0
	
	is_reloading = false
	can_shoot = true

func swing_recover():
	while swing_amount < max_swing:
		await get_tree().create_timer(1.0).timeout #I'm losing my mind
		swing_amount +=1
	recovering = false

func dash():
	#print("im being called")
	dashing = true
	hurt_box.set_deferred("disabled", true)
	set_collision_mask_value(2, false)  # player stops seeing enemies
	set_collision_layer_value(1, false) # enemies stop seeing player
	await get_tree().create_timer(0.2).timeout
	dashing = false
	hurt_box.set_deferred("disabled", false)
	set_collision_mask_value(2, true)
	set_collision_layer_value(1, true)
	
func recharge_dash():
	while dash_amount < max_dash:
		await get_tree().create_timer(2).timeout
		dash_amount += 1
	
	recharging = false

func _on_hurt_box_hurted(hit_from: Vector2) -> void:
	
	health = hurt_box.healthpoint
	health_bar.health = health
	
	if invincible:
		return
	
	invincible = true
	
	for i in range(randi_range(7, 14)):
		var b = b_fly.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position
		b.move_dir = (global_position - hit_from).angle() + randf_range(-2.5, 2.5)
		b.z_index = -2
		
	await get_tree().create_timer(0.5).timeout #[TITLE CARD] frame
	invincible = false
	
func _on_hurt_box_died(hit_from: Vector2) -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	
	top.hide()
	legs.hide()
	#top.offset.y += 20
	#top.flip_v = true
	
	blunt_hand.hide()
	sharp_hand.hide()
	pistol_hand.hide()
	second_hand.hide()
	
	#hit_box.set_deferred("disabled", true)
	col_shape.set_deferred("disabled", true)
	hurt_box.set_deferred("disabled", true)
	
	for i in range(randi_range(1, 1)):
		var b = p_die.instantiate()
		var dir_f_player = (global_position - hit_from).normalized()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position
		b.move_dir = (global_position - hit_from).angle()
		b.rotation = dir_f_player.angle() + deg_to_rad(90)
		b.z_index = -1
		
	for i in range(randi_range(25, 40)):
		var b = b_puddle.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		b.move_dir = (global_position - hit_from).angle() + randf_range(-0.5, 0.5)
		b.z_index = -2
		
		await get_tree().create_timer(0.25).timeout
		death_screen.show()
	
func switch_weapon_next():
	#print("im being called, switch next")
	if !can_melee:
		return
	if is_dead:
		return
		
	if weapons.is_empty():
		print("No weapon")
		return
		
	melee_id += 1
	#top.flip_h = false
	#combo_step = 1
	weapons[current_weapon].node.hide()
	current_weapon = (current_weapon + 1) % weapons.size()
	weapons[current_weapon].node.show()
	hit_box.damage = weapons[current_weapon].damage
	_update_holding_state()

func switch_weapon_prev():
	#print("im being called, switch prev")
	if !can_melee:
		return
		
	if is_dead:
		return
		
	if weapons.is_empty():
		print("No weapon")
		return
	melee_id += 1
	#top.flip_h = false
	#combo_step = 1
	weapons[current_weapon].node.hide()
	current_weapon = (current_weapon - 1 + weapons.size()) % weapons.size()
	weapons[current_weapon].node.show()
	hit_box.damage = weapons[current_weapon].damage
	_update_holding_state()
	
func _update_holding_state():
	
	if weapons.is_empty() or current_weapon >= weapons.size() or current_weapon < 0:
		current_weapon = 0
		return
	
	var t = weapons[current_weapon].type
	
	#disable the gun first
	for w in weapons:
		if w.node.has_method("set_active_weapon"):
			w.node.set_active_weapon(false)
	
	is_holding_melee = false
	is_holding_pistol = false
	blunt_hand.hide()
	sharp_hand.hide()
	pistol_hand.hide()
	second_hand.hide()

	if t == WeaponData.Type.melee_blunt:
		is_holding_melee = true
		blunt_hand.show()
		#melee_on_right = true
		#hand.position = melee_pos_right
		hb_box.shape.size = Vector2(24, 16)
		top.flip_h = !melee_on_right
		weapons[current_weapon].node.rotation_degrees = 0
	elif t == WeaponData.Type.melee_sharp:
		is_holding_melee = true
		sharp_hand.show()
		#melee_on_right = true
		#hand.position = melee_pos_right
		if weapons[current_weapon].name == "katana":
			hb_box.shape.size = Vector2(20, 80)
		else:
			hb_box.shape.size = Vector2(45, 35)
		top.flip_h = false
		weapons[current_weapon].node.rotation_degrees = -90
	elif t == WeaponData.Type.pistol:
		is_holding_pistol = true
		pistol_hand.show()
		top.flip_h = false
		hb_box.shape.size = Vector2(24, 16)
		weapons[current_weapon].node.rotation_degrees = -90
		weapons[current_weapon].node.set_active_weapon(true)
	elif t == WeaponData.Type.second:
		is_holding_second = true
		second_hand.show()
		top.flip_h = false
		hb_box.shape.size = Vector2(24, 16)
		weapons[current_weapon].node.rotation_degrees = -90
		weapons[current_weapon].node.set_active_weapon(true)

func apply_knockback(force: Vector2):
	knockback = force

func interact():
	var items = get_tree().get_nodes_in_group("item")
	for item in items:
		#print(item.player_nearby)
		if item.player_nearby:
			item.pick_up()
			return
