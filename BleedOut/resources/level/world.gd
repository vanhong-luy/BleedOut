extends Node2D

var player_scene = preload("res://resources/player/scenes/player.tscn")

func _ready() -> void:
	var spawn = get_tree().get_first_node_in_group("PlayerSpawn")
	if spawn:
		var player = player_scene.instantiate()
		add_child(player)
		player.global_position = spawn.global_position
