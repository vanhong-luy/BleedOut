extends CharacterBody2D

@onready var shop_area: Area2D = $ShopArea
var is_entered: bool = false
@onready var player = get_tree().get_first_node_in_group("player")

#==== shop part ====
@onready var shop: CanvasLayer = $Shop
#close
@onready var close: Button = $Shop/Panel/Close
#var item? lmao idk what to name this comment
var item

#boolet
var boolet: int


func _ready() -> void:
	shop.hide()
	shop.process_mode = Node.PROCESS_MODE_ALWAYS
	
func _physics_process(_delta: float) -> void:
	if not is_entered: return
	if Input.is_action_just_pressed("interact") and is_entered:
		shop.show()
		get_tree().paused = true


func _on_shop_area_body_entered(body: Node2D) -> void:
	#if body != player: return
	if body.is_in_group("player"):
		is_entered = true

func _on_shop_area_body_exited(body: Node2D) -> void:
	#if body != player: return
	if body.is_in_group("player"):
		is_entered = false
		shop.hide()
		get_tree().paused = false
		
func _on_close_pressed() -> void:
	shop.hide()
	get_tree().paused = false
	
@warning_ignore("shadowed_variable")
func weapon_setup(item: WeaponData) -> Dictionary:
	var new_player = get_tree().get_first_node_in_group("player")
	var node = item.scene.instantiate()
	var target_hand
	if item.type == WeaponData.Type.pistol:
		target_hand = new_player.pistol_hand
	elif item.type == WeaponData.Type.melee_sharp:
		target_hand = new_player.sharp_hand
	elif item.type == WeaponData.Type.second:
		target_hand = new_player.second_hand
	else:
		target_hand = new_player.blunt_hand

	target_hand.add_child(node)
	node.hide()
	return {
		"name": item.name,
		"damage": item.damage,
		"node": node,
		"type": item.type,
		"mag_cap": item.mag_cap,
		"max_mag": item.max_mag,
		"spare_ammo": item.spare_ammo,
		"max_spare": item.max_spare,
		"fire_rate": item.fire_rate
	}
	
#======== PISTOL SECTION ========
func _on_b_92_pressed() -> void:
	item = load("res://resources/weapon/data/pistol/b_92.tres")
	var new_player = get_tree().get_first_node_in_group("player")
	
	for weapon in new_player.weapons:
		if weapon["name"] == item.name:
			if new_player.total_money < item.refill_price:
				print("broke ahh, cant even buy ammo")
				return
			if weapon["spare_ammo"] >= weapon["max_spare"]:
				return
			new_player.total_money -= item.refill_price
			boolet = item.mag_cap
			weapon["spare_ammo"] = min(weapon["spare_ammo"] + boolet, item.max_spare)
			return
	
	if new_player.total_money < item.price:
		print("sorry, you're broke")
		return
	new_player.total_money -= item.price
	var weapon_data = weapon_setup(item)
	new_player.weapons.append(weapon_data)
	new_player.weapon_list.append(item)
	
	new_player.switch_weapon_last()
	
func _on_d_cobra_pressed() -> void:
	item = load("res://resources/weapon/data/pistol/d_cobra.tres")
	var new_player = get_tree().get_first_node_in_group("player")
	
	for weapon in new_player.weapons:
		if weapon["name"] == item.name:
			if new_player.total_money < item.refill_price:
				print("broke ahh, cant even buy ammo")
				return
			if weapon["spare_ammo"] >= weapon["max_spare"]:
				return
			new_player.total_money -= item.refill_price
			boolet = item.mag_cap
			weapon["spare_ammo"] = min(weapon["spare_ammo"] + boolet, item.max_spare)
			return
	
	if new_player.total_money < item.price:
		print("sorry, you're broke")
		return
	new_player.total_money -= item.price
	var weapon_data = weapon_setup(item)
	new_player.weapons.append(weapon_data)
	new_player.weapon_list.append(item)
	
	new_player.switch_weapon_last()
	
#======== SHOTGUN SECTION ========
func _on_m_500_pressed() -> void:
	item = load("res://resources/weapon/data/second/m_500.tres")
	var new_player = get_tree().get_first_node_in_group("player")
	
	for weapon in new_player.weapons:
		if weapon["name"] == item.name:
			if new_player.total_money < item.refill_price:
				print("broke ahh, cant even buy ammo")
				return
			if weapon["spare_ammo"] >= weapon["max_spare"]:
				return
			new_player.total_money -= item.refill_price
			boolet = item.mag_cap
			weapon["spare_ammo"] = min(weapon["spare_ammo"] + boolet, item.max_spare)
			return
	
	if new_player.total_money < item.price:
		print("sorry, you're broke")
		return
	new_player.total_money -= item.price
	var weapon_data = weapon_setup(item)
	new_player.weapons.append(weapon_data)
	new_player.weapon_list.append(item)
	
	new_player.switch_weapon_last()

#======== RIFLE SECTION ========
func _on_ak_pressed() -> void:
	item = load("res://resources/weapon/data/second/ak.tres")
	var new_player = get_tree().get_first_node_in_group("player")
	
	for weapon in new_player.weapons:
		if weapon["name"] == item.name:
			if new_player.total_money < item.refill_price:
				print("broke ahh, cant even buy ammo")
				return
			if weapon["spare_ammo"] >= weapon["max_spare"]:
				return
			new_player.total_money -= item.refill_price
			boolet = item.mag_cap
			weapon["spare_ammo"] = min(weapon["spare_ammo"] + boolet, item.max_spare)
			return
	
	if new_player.total_money < item.price:
		print("sorry, you're broke")
		return
	new_player.total_money -= item.price
	var weapon_data = weapon_setup(item)
	new_player.weapons.append(weapon_data)
	new_player.weapon_list.append(item)
	
	new_player.switch_weapon_last()
