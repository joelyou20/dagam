extends "res://addons/gut/test.gd"

const PlayerInteract = preload("res://Scripts/Player/PlayerInteract.gd")
const Interactable = preload("res://Scripts/Utils/Interactable.gd")

var interact: PlayerInteract
var fake_target: InteractableMock
var player_node: Node3D

func before_each():
	interact = PlayerInteract.new()
	player_node = Node3D.new()
	interact.player = player_node
	player_node.add_child(interact)

	fake_target = InteractableMock.new()
	add_child(player_node)

func after_each():
	player_node.queue_free()
	await get_tree().process_frame

func test_update_last_input_works():
	interact.update_last_input(Vector2(1, 0))
	assert_eq(interact.last_input_vector, Vector3(1, 0, 0).normalized())

func test_update_last_input_does_not_change_on_small_input():
	var initial = interact.last_input_vector
	interact.update_last_input(Vector2(0.01, 0.01))
	assert_eq(interact.last_input_vector, initial)

func test_add_target_adds_once_only():
	interact.add_target(fake_target)
	interact.add_target(fake_target)
	assert_eq(interact.nearby_targets.size(), 1)

func test_remove_target_removes_correctly():
	interact.add_target(fake_target)
	interact.remove_target(fake_target)
	assert_eq(interact.nearby_targets.size(), 0)

func test_update_best_target_selects_visible_target():
	interact.nearby_targets = [fake_target]
	interact._update_best_target()
	assert_eq(interact.current_target, fake_target)
	assert_true(fake_target.visible)
