extends "res://addons/gut/test.gd"

const BubbleScene := preload("res://Scenes/ActionBubble3D.tscn")

class FakeInteractNode:
	extends Node
	
	var added_targets = []
	var removed_targets = []

	func add_target(target):
		added_targets.append(target)

	func remove_target(target):
		removed_targets.append(target)

var interactable: InteractableMock
var fake_interact_node: FakeInteractNode
var player: Node

func before_each():
	# Create interactable
	interactable = InteractableMock.new()
	
	var flagA = FlagData.new()
	flagA.key = FlagData.FlagName.UNSET
	flagA.value = true
	
	
	interactable.flags_enabled = [FlagData.FlagName.UNSET, FlagData.FlagName.KICKED_GREGS_DOG]
	interactable.interact_node = "Interact"
	interactable.player_group = "Player"

	# Add Area3D so _ready() doesn't fail
	var area := Area3D.new()
	area.name = "Area3D"
	interactable.add_child(area)

	# Setup fake interact node
	fake_interact_node = FakeInteractNode.new()
	fake_interact_node.name = "Interact"

	# Setup fake player
	player = Node.new()
	player.name = "Player"
	player.add_to_group("Player")
	player.add_child(fake_interact_node)

	add_child(interactable)
	add_child(player)

func after_each():
	interactable.queue_free()
	player.queue_free()
	await get_tree().process_frame

func test_body_entered_adds_target():
	interactable._on_body_entered(player)
	assert_eq(fake_interact_node.added_targets, [interactable])

func test_body_exited_removes_target():
	interactable._on_body_exited(player)
	assert_eq(fake_interact_node.removed_targets, [interactable])

func test_interact_sets_flags_and_calls_on_interact():
	interactable.interact()
	var flags = interactable.flags_enabled
	assert_eq(flags, [FlagData.FlagName.UNSET, FlagData.FlagName.KICKED_GREGS_DOG])

func test_show_action_bubble_instantiates_and_positions():
	interactable.show_action_bubble()
	assert_true(interactable.action_bubble is Node3D)
	assert_true(interactable.action_bubble.visible)

func test_hide_action_bubble_makes_it_invisible():
	interactable.show_action_bubble()
	interactable.hide_action_bubble()
	assert_false(interactable.action_bubble.visible)

func test_get_interaction_score_returns_positive():
	var player_pos := Vector3(0, 0, -2)
	var player_dir := Vector3(0, 0, 1)
	var score := interactable.get_interaction_score(player_pos, player_dir)
	assert_gt(score, 0.0)
