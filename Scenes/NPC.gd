extends Node3D

@export var player_group: String = "Player"
@onready var icon := $ActionBubble

func _ready():
	icon.visible = false  # Hide icon by default
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node):
	if body.is_in_group(player_group):
		icon.visible = true
		print("Player is near the NPC.")

func _on_body_exited(body: Node):
	if body.is_in_group(player_group):
		icon.visible = false
		print("Player walked away from the NPC.")
