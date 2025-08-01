extends Node

var current_scene: Node = null
@onready var fade_layer: FadeLayer = preload("res://Scenes/FadeScene.tscn").instantiate() as FadeLayer
@onready var scene_root: Node = get_tree().get_root().get_node("World/SceneRoot")
	
func initialize():
	get_tree().get_root().add_child(fade_layer)
	fade_layer.initialize()

func transition_to_scene(path: String, spawn_point_name: String = "PlayerSpawn"):
	fade_layer.fade_out()
	_load_scene(path, spawn_point_name)

func _load_scene(path: String, spawn_point_name: String = ""):
	if current_scene:
		current_scene.queue_free()

	var new_scene = load(path).instantiate()
	scene_root.add_child(new_scene)
	current_scene = new_scene

	var player = get_tree().get_nodes_in_group("Player")[0]
	var spawn_point = new_scene.get_node_or_null(spawn_point_name)
	if player and spawn_point:
		player.global_transform.origin = spawn_point.global_transform.origin

	fade_layer.fade_in()
