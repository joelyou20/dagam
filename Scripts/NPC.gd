extends Node3D

@onready var action_bubble := $ActionBubble

@export var player_group: String = "Player"
@export var interact_node: String = "Interact"
@export var interaction_priority: int = 1
@export var display_name: String = ""

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
	print("Talking to: %s" % name)
	DialogManager.show_dialog([
		"Hello, I'm " + name + "! Nice to meet you.",
		"This is a second line of dialog to test sequencing."
	], display_name)
