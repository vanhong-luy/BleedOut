extends Area2D
@export var next_scene: String = ""
var is_entered = false

func _on_body_entered(body: Node2D) -> void:
	#print("ENTERED: ", body.name, " | is_entered was: ", is_entered)
	if is_entered: return
	if not body.is_in_group("player"): return
	
	is_entered = true
	GameState.save_player(body)
	GameState.score_conversion()
	get_tree().call_deferred("change_scene_to_file", next_scene)
