class_name PlayerMovement
extends Node
@export var speed = 5.0
@export var gravity := 9.8
var input_direction := Vector2.ZERO
var interaction_handler := InteractionHandler
var _preferred_axis := 0
@onready var player = get_parent()

func move(delta):
	if interaction_handler.is_blocked():
		input_direction = Vector2.ZERO

		return

	var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var horizontal_pressed = (
		Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right")
	)
	var vertical_pressed = (
		Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down")
	)
	var cardinal = _cardinal_input(input, horizontal_pressed, vertical_pressed)

	input_direction = cardinal
	var direction = Vector3(cardinal.x, 0, cardinal.y)

	if direction:
		player.velocity.x = direction.x * speed
		player.velocity.z = direction.z * speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, speed)
		player.velocity.z = move_toward(player.velocity.z, 0, speed)

	if player.is_on_floor():
		player.velocity.y = 0
	else:
		player.velocity.y -= gravity * delta

	player.move_and_slide()

func _cardinal_input(
	input: Vector2, horizontal_pressed := false, vertical_pressed := false
) -> Vector2:
	if input.is_zero_approx():
		return Vector2.ZERO

	# The newest perpendicular key wins. Equal simultaneous inputs keep the last
	# axis, while analogue input uses its stronger axis instead of a diagonal.

	if horizontal_pressed != vertical_pressed:
		_preferred_axis = 0 if horizontal_pressed else 1
	elif not is_equal_approx(absf(input.x), absf(input.y)):
		_preferred_axis = 0 if absf(input.x) > absf(input.y) else 1

	if _preferred_axis == 0 and is_zero_approx(input.x):
		_preferred_axis = 1
	elif _preferred_axis == 1 and is_zero_approx(input.y):
		_preferred_axis = 0

	return Vector2(signf(input.x), 0) if _preferred_axis == 0 else Vector2(0, signf(input.y))
