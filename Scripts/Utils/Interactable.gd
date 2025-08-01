extends Node3D
class_name Interactable

@export var flags_enabled: Array[FlagData.FlagName]
@export var player_group: String = "Player"
@export var interaction_priority: int = 1

var interact_node: String = "Interact"

const BubbleScene := preload("res://Scenes/ActionBubble3D.tscn")

var action_bubble: Node3D
var is_enabled: bool = true

func _ready():
	var area = $Area3D
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
func interact():
	for flag in flags_enabled:
		FlagManager.set_flag(flag)
	_on_interact()
	
func _on_interact():
	push_error("_on_interact() not implemented in " + str(self))

func show_action_bubble():
	if not action_bubble:
		action_bubble = BubbleScene.instantiate()
		add_child(action_bubble)
		var height = _calculate_height()
		action_bubble.position = Vector3(0, height + 0.3, 0)
	action_bubble.visible = true
	
func _calculate_height() -> float:
	var max_height := 0.0
	for child in get_children():
		if child is MeshInstance3D:
			var aabb: AABB = child.get_aabb()
			var top_y := aabb.position.y + aabb.size.y
			if top_y > max_height:
				max_height = top_y
	return max_height


func hide_action_bubble():
	if action_bubble:
		action_bubble.visible = false

func is_interactable() -> bool:
	return is_enabled and self.is_inside_tree()

# Optional scoring override for advanced prioritization
func get_interaction_score(player_position: Vector3, player_direction: Vector3) -> float:
	var to_target = (global_transform.origin - player_position)
	var distance_score = 1.0 / (to_target.length() + 0.01)
	var direction_score = to_target.normalized().dot(player_direction)
	return distance_score + direction_score

func _on_body_entered(body):
	if body.is_in_group(player_group):
		body.get_node(interact_node).add_target(self)

func _on_body_exited(body):
	if body.is_in_group(player_group):
		body.get_node(interact_node).remove_target(self)
