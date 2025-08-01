extends Interactable

@export var target_scene: String
@export var spawn_point_name: String = "PlayerSpawn"
@export var auto_transition := false

func _on_body_entered(body):
	if body.is_in_group(player_group):
		body.get_node(interact_node).add_target(self)

		if auto_transition:
			_transition()

func _transition():
	if target_scene != "":
		var scene_path := target_scene

		if not scene_path.begins_with("res://Scenes/"):
			scene_path = "res://Scenes/" + scene_path

		if not scene_path.ends_with(".tscn"):
			scene_path += ".tscn"

		SceneManager.transition_to_scene(scene_path, spawn_point_name)

func _on_interact():
	_transition()
