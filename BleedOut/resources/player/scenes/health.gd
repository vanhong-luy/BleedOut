extends ProgressBar

@onready var player = get_tree().get_first_node_in_group("player")
@onready var timer: Timer = $Timer
@onready var damage_bar: ProgressBar = $DamageBar

var health = 0 : set = _set_health


func _ready() -> void:
	add_to_group("health_bar")

func _set_health(new_health):
	var prev_health = health
	var style = get_theme_stylebox("fill").duplicate()
	health = min(max_value, new_health)
	value = health
	if health > 40:
		style.bg_color = Color.WEB_GREEN
	elif health > 20:
		style.bg_color = Color.ORANGE
	else:
		style.bg_color = Color.RED
	add_theme_stylebox_override("fill", style)
	
	if health <= 0:
		queue_free()
		
	if health < prev_health:
		timer.start()
	else:
		damage_bar.value = health

func init_health(health):
	health = player.health
	max_value = health
	value = health
	damage_bar.max_value = health
	damage_bar.value = health


func _on_timer_timeout() -> void:
	damage_bar.value = health
