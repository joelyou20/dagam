extends "res://addons/gut/test.gd"

const Door = preload("res://Scripts/Utils/Door.gd")
const SceneManagerBase = preload("res://Scripts/Managers/SceneManager.gd")

class FakeInteractNode:
	extends Node
	var added_targets = []

	func add_target(target):
		added_targets.append(target)


var door: Door
var fake_scene_manager: SceneManagerMock
var player: Node
var fake_interact_node: FakeInteractNode

func before_each():
	fake_scene_manager = SceneManagerMock.new()
	var world = Node3D.new()
	world.name = "World"
	var scene_root = Node3D.new()
	scene_root.name = "SceneRoot"
	world.add_child(scene_root)
	get_tree().get_root().add_child(world)

	door = Door.new()
	door.name = "TestDoor"
	door.target_scene = "TestScene"
	door.spawn_point_name = "CustomSpawn"
	door.auto_transition = true
	door.scene_manager = fake_scene_manager
	door.player_group = "Player"
	door.interact_node = "Interact"

	# Add required Area3D node before _ready()
	var area = Area3D.new()
	area.name = "Area3D"
	door.add_child(area)

	# Setup fake player
	player = Node.new()
	player.name = "Player"
	player.add_to_group("Player")

	# Setup fake interact node
	fake_interact_node = FakeInteractNode.new()
	fake_interact_node.name = "Interact"
	player.add_child(fake_interact_node)

	add_child(door)   # Now _ready() runs safely
	add_child(player)

func after_each():
	door.queue_free()
	await get_tree().process_frame

func test_on_body_entered_adds_target_and_triggers_transition():
	door._on_body_entered(player)

	assert_eq(fake_interact_node.added_targets, [door])
	assert_eq(fake_scene_manager.last_scene_path, "res://Scenes/Environments/TestScene.tscn")
	assert_eq(fake_scene_manager.last_spawn_point, "CustomSpawn")

func test_transition_does_not_add_prefix_or_suffix_twice():
	door.target_scene = "res://Scenes/CustomArea/Intro.tscn"
	door._transition()

	assert_eq(fake_scene_manager.last_scene_path, "res://Scenes/CustomArea/Intro.tscn")
	assert_eq(fake_scene_manager.last_spawn_point, "CustomSpawn")
