extends Node2D

@export var enemy: Array[PackedScene] = []
@onready var en_spawn_point = $SpawnPoint.get_children()
@onready var doors = $Door.get_children()

@onready var trigger_area: Area2D = $TriggerArea

var spawn_warning = preload("res://resources/level/other/spawn_warning.tscn")



var current_enemy = 0

@export var total_round: int = 1
var current_round = 1
var is_room_clear = false

var next_round_available = false

func _ready():
	trigger_area.body_entered.connect(_on_trigger_area_body_entered)

func _on_trigger_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_room_clear:
		trigger_area.set_deferred("monitoring", false)
		lock_door()
		#await get_tree().create_timer(0.8).timeout
		call_deferred("spawnEnemy")
		
func spawnEnemy():
	#print("Total Round: ", total_round)
	var warnings = Warning()
	await get_tree().create_timer(0.5).timeout
	
	for w in warnings:
		w.queue_free()
		
	var spawned = 0
	for p in en_spawn_point:
		if p.wave_spawn != current_round:
			continue
			
		var e = null
		if p.enemy:
			e = p.enemy.instantiate()
		else:
			e = enemy.pick_random().instantiate()
		add_child(e)
		e.global_position = p.global_position
		current_enemy += 1
		spawned += 1
		e.died.connect(_on_enemy_died)
	
	if spawned == 0:
		next_round()
		
func _on_enemy_died():
	current_enemy -= 1
	if current_enemy <= 0:
		#call in next round instead
		next_round()
		
func next_round():
	if current_round < total_round:
		current_round += 1
		call_deferred("spawnEnemy")
	else:
		is_room_clear = true
		unlock_door()

func lock_door():
	for d in doors:
		d.lock()
		
func unlock_door():
	for d in doors:
		d.unlock()

func Warning():
	var warnings = []
	for p in en_spawn_point:
		if p.wave_spawn != current_round:
			continue
			
		var warning = spawn_warning.instantiate()
		get_tree().current_scene.add_child(warning)
		warning.global_position =p.global_position
		warning.z_index = 2
		warnings.append(warning)
	return warnings

func register_enemy(e: Node) -> void:
	current_enemy += 1
	e.died.connect(_on_enemy_died)
