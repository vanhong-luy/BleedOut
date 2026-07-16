#This door unlocked if only an item was picked up
extends StaticBody2D

@onready var door: CollisionShape2D = $CollisionShape2D
@onready var door_node: TileMapLayer = $TileMapLayer



func _ready():
	
	door.set_deferred("disabled", true)
	door_node.visible = true

func _physics_process(_delta: float) -> void:
	var item = get_tree().get_first_node_in_group("item")
	#print(is_instance_valid(item))
	if not is_instance_valid(item):
		unlock()
		return
	if item.picked_up:
		unlock()
	else:
		lock()

func lock():
	door.set_deferred("disabled", false)
	door_node.visible = true
	
func unlock():
	door.set_deferred("disabled", true)
	door_node.visible = false
