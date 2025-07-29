extends Node

@export var speed = 5.0
@onready var player = get_parent()

func move(delta):
	if InteractionHandler.is_blocked():
		return
	
	var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (player.transform.basis * Vector3(input.x, 0, input.y)).normalized()
	
	if direction:
		player.velocity.x = direction.x * speed
		player.velocity.z = direction.z * speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, speed)
		player.velocity.z = move_toward(player.velocity.z, 0, speed)

	player.move_and_slide()
