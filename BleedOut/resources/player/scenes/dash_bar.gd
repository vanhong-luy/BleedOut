extends Control

@onready var player = get_tree().get_first_node_in_group("player")
@onready var dash_bar = [$DashBar3, $DashBar2, $DashBar1]

func _ready() -> void:
	add_to_group("dash_bar")
	
func update_dash(amount: int):
	for bar in dash_bar.size():
		dash_bar[bar].visible = bar < amount
