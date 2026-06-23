extends Label

@onready var player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	text = str("Health: ", roundi(player.health))
