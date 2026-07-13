extends Button
@onready var shop: CanvasLayer = $"../.."

func _button_pressed():
	shop.hide()
