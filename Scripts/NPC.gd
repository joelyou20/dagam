extends Node3D

@onready var action_bubble := $ActionBubble

@export var interaction_priority: int = 1
@export var display_name: String = ""

var interact_node: String = "Interact"
var player_group: String = "Player"

func _ready():
	action_bubble.visible = false
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)
	
	if display_name == "":
		display_name = name

func _on_body_entered(body):
	if body.is_in_group(player_group):
		body.get_node(interact_node).add_target(self)

func _on_body_exited(body):
	if body.is_in_group(player_group):
		body.get_node(interact_node).remove_target(self)

func show_action_bubble():
	action_bubble.visible = true

func hide_action_bubble():
	action_bubble.visible = false

func interact():
	DialogManager.show_dialog_by_npc_id(name)
