extends Control

@onready var player = get_tree().get_first_node_in_group("player")
@onready var swing_bar = [$SwingBar3, $SwingBar2, $SwingBar1]

func _ready() -> void:
	add_to_group("swing_bar")
	
func update_swing(amount: int):
	for swing in swing_bar.size():
		swing_bar[swing].visible = swing < amount
