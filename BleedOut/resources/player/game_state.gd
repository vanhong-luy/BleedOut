extends Node
var player_node: Node = null
var player_scene: PackedScene = preload("res://resources/player/scenes/player.tscn")
var saved_data = {}

var score: int = 0
var money: int = 0


func save_player(player):
	saved_data = {
		"health": player.health,
		"current_weapon": player.current_weapon,
		"weapon_list": player.weapon_list,
		"ammo": [],
		"score": player.total_score
	}
	for w in player.weapons:
		saved_data.ammo.append({
			"mag_cap": w.mag_cap,
			"spare_ammo": w.spare_ammo
		})
	player_node = player
	player.get_parent().remove_child(player)

func load_player(scene_root):
	#print("load_player called, saved_data: ", saved_data)
	var spawn = scene_root.get_tree().get_first_node_in_group("PlayerSpawn")
	
	if player_node != null:
		# carry over from transition
		scene_root.add_child(player_node)
		if spawn:
			player_node.global_position = spawn.global_position
			_apply_camera(player_node, spawn)
	else:
		var player = player_scene.instantiate()
		if !saved_data.is_empty():
			player.weapon_list = saved_data.weapon_list
		scene_root.add_child(player)
		await scene_root.get_tree().process_frame
		if spawn:
			player.global_position = spawn.global_position
			_apply_camera(player, spawn)
		if saved_data != null and !saved_data.is_empty():
			# if you want it to load player's previous health,
			# use this saved_data.health on both 100
			player.health = 100
			player.hurt_box.healthpoint = 100
			player.current_weapon = saved_data.current_weapon
			for i in range(player.weapons.size()):
				if i < saved_data.ammo.size():
					player.weapons[i].mag_cap = saved_data.ammo[i].mag_cap
					player.weapons[i].spare_ammo = saved_data.ammo[i].spare_ammo
			player.total_score = saved_data.score

func _apply_camera(player, spawn):
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		camera.limit_left = spawn.limit_left
		camera.limit_top = spawn.limit_top
		camera.limit_right = spawn.limit_right
		camera.limit_bottom = spawn.limit_bottom
		camera.make_current()
