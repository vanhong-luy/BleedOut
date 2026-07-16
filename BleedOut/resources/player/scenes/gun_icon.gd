extends TextureRect

@onready var player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	if player.weapons.is_empty() or player.current_weapon >= player.weapons.size() or player.current_weapon < 0:
		player.current_weapon = 0
		return
	
	var weapon = player.weapons[player.current_weapon]
	
	texture = weapon["weapon_texture"]
