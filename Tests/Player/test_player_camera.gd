extends "res://addons/gut/test.gd"

const PlayerCamera = preload("res://Scripts/Player/PlayerCamera.gd")

var camera: PlayerCamera
var fake_input : InputMock
var fake_handler : InteractionHandlerMock

func before_each():
	fake_handler = InteractionHandlerMock.new()
	
	camera = PlayerCamera.new()
	fake_input = InputMock.new()
	fake_input.action_strengths["ui_right"] = 1.0
	camera.input_handler = fake_input  # inject fake
	camera.position = Vector3.ZERO
	camera.max_offset = 1.0
	camera.lead_strength = 1.0
	camera.pull_speed = 10.0
	camera.return_speed = 10.0
	camera.interaction_handler = fake_handler  # inject fake

	add_child(camera)
	camera._ready()

func after_each():
	camera.queue_free()
	await get_tree().process_frame

func test_camera_leads_when_moving():
	var fake_input := InputMock.new()
	fake_input.action_strengths["ui_right"] = 1.0
	
	camera.input_handler = fake_input  # This works because fake_input has the same method
	
	var input_vector := Vector2(1, 0)
	var target := camera.camera_lead(input_vector, true)

	assert_ne(target, camera.default_position)
	assert_eq(target, Vector3(1, 0, 0))  # Adjust based on your camera's settings

func test_camera_does_not_lead_when_blocked():
	fake_handler.block("test")
	var target := camera.camera_lead(Vector2(1, 0), true)
	assert_eq(target, camera.default_position)
	assert_eq(camera.target_offset, Vector3.ZERO)

func test_camera_returns_to_center_when_not_moving():
	var target := camera.camera_lead(Vector2(0, 0), false)
	assert_eq(target, camera.default_position)
	assert_eq(camera.target_offset, Vector3.ZERO)

func test_process_moves_toward_target():
	camera.default_position = Vector3.ZERO
	camera.position = Vector3.ZERO
	camera.max_offset = 1.0
	camera.lead_strength = 1.0
	camera.pull_speed = 2.0
	camera.return_speed = 6.0

	var fake_input := InputMock.new()
	fake_input.action_strengths["ui_right"] = 1.0
	camera.input_handler = fake_input

	camera._process(0.1)

	assert_gt(camera.position.x, 0.0)
