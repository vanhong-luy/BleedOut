extends Area2D

@export var item_id: String
@export var item_sprite: Texture2D
@export var item: WeaponData
@export var ammo_drop: int = 0

@onready var sprite: Sprite2D = $Sprite2D

var picked_up = false

var player_nearby: bool = false

func _ready() -> void:
	add_to_group("item")
	print(get_tree().get_nodes_in_group("item"))
	if item_sprite:
		sprite.texture = item_sprite


func _on_body_entered(body: Node2D) -> void:
	#print("something entered item: ", body.name)
	if body.name == "Player":
		player_nearby = true
		#print("yo, it's me, if body == player. im being called")
	#print("Is player nearby? ", player_nearby)
		
func pick_up():
	var player = get_tree().get_first_node_in_group("player")
	
	for weapon in player.weapons:
		if weapon["name"] == item.name:
			weapon["spare_ammo"] += ammo_drop
			if weapon["spare_ammo"] >= item.spare_ammo:
				weapon["spare_ammo"] = item.spare_ammo
			queue_free()
			return
	
	var node = item.scene.instantiate()
	var target_hand
	if item.type == WeaponData.Type.pistol:
		target_hand = player.pistol_hand
	elif item.type == WeaponData.Type.melee_sharp:
		target_hand = player.sharp_hand
	elif item.type == WeaponData.Type.second:
		target_hand = player.second_hand
	else:
		target_hand = player.blunt_hand

	target_hand.add_child(node)
	node.hide()

	player.weapons.append({
		"name": item.name,
		"damage": item.damage,
		"node": node,
		"type": item.type,
		"mag_cap": item.mag_cap,
		"max_mag": item.max_mag,
		"spare_ammo": item.spare_ammo,
		"fire_rate": item.fire_rate
	})
	player.weapon_list.append(item)
	picked_up = true
	queue_free()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_nearby = false
