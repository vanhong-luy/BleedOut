extends Area2D
@export var next_scene: String = ""

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.save_player(body)
		get_tree().call_deferred("change_scene_to_file", next_scene)
