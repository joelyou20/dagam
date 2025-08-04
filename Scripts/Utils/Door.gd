extends Interactable
@export var target_scene: String
@export var spawn_point_name: String = "PlayerSpawn"
@export var auto_transition := false
var scene_manager := SceneManager  # Allow injection for testing

func _on_body_entered(body):
	# Don't trigger in the editor
	if Engine.is_editor_hint():
		return
	
	# Call the parent class method to handle interaction setup
	super._on_body_entered(body)
	
	# Door-specific logic for auto transition
	if body.is_in_group(player_group) and auto_transition:
		_transition()

func _transition():
	if target_scene != "":
		var scene_path := target_scene
		if not scene_path.begins_with("res://Scenes/"):
			scene_path = "res://Scenes/Environments/" + scene_path
		if not scene_path.ends_with(".tscn"):
			scene_path += ".tscn"
		scene_manager.load_scene(scene_path, true, true, spawn_point_name, 0.25)

func _on_interact():
	_transition()
