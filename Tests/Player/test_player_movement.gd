extends "res://addons/gut/test.gd"

var movement: PlayerMovement
var player: PlayerControllerMock
var interaction_handler: InteractionHandlerMock

func before_each():
	player = PlayerControllerMock.new()
	interaction_handler = InteractionHandlerMock.new()

	movement = PlayerMovement.new()
	movement.interaction_handler = interaction_handler
	movement.reparent(player)
	player.add_child(movement)

	# Inject the mock player as the parent
	movement.set_script(PlayerMovement)  # Ensure movement still runs its logic
	add_child(player)

func after_each():
	player.queue_free()
	await get_tree().process_frame
	interaction_handler.clear_blockers()

func test_move_applies_velocity_when_not_blocked():
	var input = InputMock.new()
	
	interaction_handler.clear_blockers()

	Input.action_press("ui_right")

	movement.move(0.1)

	assert_gt(player.velocity.x, 0.0)
	assert_eq(player.velocity.z, 0.0)

	Input.action_release("ui_right")

func test_move_stops_velocity_when_no_input():
	player.velocity = Vector3(5, 0, 5)

	Input.action_press("ui_right")
	Input.action_release("ui_right")

	movement.move(0.1)

	assert_lt(player.velocity.x, 5.0)
	assert_lt(player.velocity.z, 5.0)

func test_move_does_nothing_if_blocked():
	interaction_handler.block("test")

	player.velocity = Vector3(10, 0, 10)

	movement.move(0.1)

	assert_eq(player.velocity.x, 10.0)
	assert_eq(player.velocity.z, 10.0)
	
