extends ProgressBar

#@onready var boss = get_tree().get_first_node_in_group("boss")
@onready var timer: Timer = $Timer
@onready var boss_damage_bar: ProgressBar = $BossDamageBar


var health = 0 : set = _set_health


func _ready() -> void:
	add_to_group("boss_health_bar")

func _set_health(new_health):
	var prev_helth = health
	health = min(max_value, new_health)
	value = health
	if health <= 0:
		queue_free()
		
	if health < prev_helth:
		timer.start()
	else:
		boss_damage_bar.value = health

func init_health(new_health):
	health = new_health
	max_value = health
	value = health
	boss_damage_bar.max_value = health
	boss_damage_bar.value = health


func _on_timer_timeout() -> void:
	boss_damage_bar.value = health
