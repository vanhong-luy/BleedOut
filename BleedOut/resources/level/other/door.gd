extends StaticBody2D

@onready var door: CollisionShape2D = $CollisionShape2D
@onready var door_node: TileMapLayer = $TileMapLayer


func _ready():
	door.set_deferred("disabled", true)
	door_node.visible = false

func lock():
	door.set_deferred("disabled", false)
	door_node.visible = true
	
func unlock():
	door.set_deferred("disabled", true)
	door_node.visible = false
