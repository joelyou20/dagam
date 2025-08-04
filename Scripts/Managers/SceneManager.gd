extends Node

@onready var fade_scene = preload("res://Scenes/FadeScene.tscn")
@onready var scene_root: Node = get_tree().get_root().get_node("World/SceneRoot")

var current_scene: Node = null
var fade_layer: FadeLayer

func transition_to_scene(path: String, spawn_point_name: String = "PlayerSpawn"):
	call_deferred("_fade_out_and_load", path, spawn_point_name)

func _fade_out_and_load(path: String, spawn_point_name: String):
	if fade_layer:
		fade_layer.fade_out()
	load_scene(path, spawn_point_name)

func load_scene(path: String, spawn_point_name: String = ""):
	if current_scene:
		current_scene.queue_free()
	var new_scene = load(path).instantiate()
	scene_root.call_deferred("add_child", new_scene)
	current_scene = new_scene
	call_deferred("_position_player", new_scene, spawn_point_name)
	call_deferred("_fade_in")

func _fade_in():
	fade_layer = fade_scene.instantiate() as FadeLayer
	get_tree().get_root().call_deferred("add_child", fade_layer)
	fade_layer.fade_in()

func _position_player(new_scene: Node, spawn_point_name: String):
	var player = get_tree().get_nodes_in_group("Player")[0]
	var spawn_point = new_scene.get_node_or_null(spawn_point_name)
	if player and spawn_point:
		if spawn_point.global_transform.basis.determinant() == 0:
			push_error("Spawn point has a zero-scale basis! Cannot apply transform.")
			return
		var transform : Transform3D = player.global_transform
		transform.origin = spawn_point.global_transform.origin
		player.global_transform = transform
