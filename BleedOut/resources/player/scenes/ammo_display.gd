extends Label

@onready var player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	if player.weapons.is_empty() or player.current_weapon >= player.weapons.size() or player.current_weapon < 0:
		player.current_weapon = 0
		return
	
	var weapon = player.weapons[player.current_weapon]
	
	if weapon["type"] == WeaponData.Type.melee_blunt or weapon["type"] == WeaponData.Type.melee_sharp:
		text = ""
		return
	
	text = str(weapon["mag_cap"], " / ", weapon["spare_ammo"])
