extends Camera2D

@export var smooth_speed := 10.0
@export var look_ahead_distance := 45.0

@onready var player = get_tree().get_first_node_in_group("player")

var velocity := Vector2.ZERO

var randomStrenght: float = 5.0
var lightRandomStrenght: float = 2.5
var shakeFade: float = 5.0
var rng = RandomNumberGenerator.new()
var shakeStrength: float = 0.0

func applyShake():
	shakeStrength = randomStrenght

func applyShakeLight():
	shakeStrength = lightRandomStrenght
	
func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shakeStrength, shakeStrength), rng.randf_range(-shakeStrength, shakeStrength))

func _process(delta):
	@warning_ignore("confusable_local_usage")
	if player.is_dead:
		return
		
	@warning_ignore("shadowed_variable")
	var player = get_parent()

	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - player.global_position).normalized()

	@warning_ignore("shadowed_variable_base_class")
	var offset = direction * look_ahead_distance

	var target_position = player.global_position + offset

	global_position = global_position.lerp(target_position, smooth_speed * delta)
