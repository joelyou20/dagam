extends Camera3D

@export_range(0.0, 1.0, 0.01)
var lead_strength: float = 0.5  # How much lead offset to apply (scaled max_offset)

@export var max_offset: float = 0.5  # Max lead offset distance
@export var pull_speed: float = 2.0  # Slower smoothing when player is moving
@export var return_speed: float = 6.0  # Faster smoothing when returning to center

var default_position: Vector3
var target_offset: Vector3 = Vector3.ZERO

func _ready():
	default_position = position

func _process(delta):
	var player = get_parent()
	if not player:
		return

	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	var moving = input_vector.length() > 0.1
	var speed = pull_speed if moving else return_speed

	if moving:
		input_vector = input_vector.normalized()
		var full_offset = Vector3(input_vector.x, 0, input_vector.y) * max_offset
		target_offset = full_offset * lead_strength
	else:
		target_offset = Vector3.ZERO

	var target_position = default_position + target_offset
	position = position.lerp(target_position, delta * speed)
