#unused

extends Area2D

@onready var top: AnimatedSprite2D = $"../top"
@onready var basic_enemy: CharacterBody2D = $".."


func _process(_delta):
	rotation = top.rotation

func _on_area_entered(area: Area2D) -> void:
	
	if area is HurtBox:
		print("you reached my push hitbox")
