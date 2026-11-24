class_name PlayerController
extends CharacterBody3D

@onready var movement = $Movement
@onready var interaction = $Interact
@onready var animation: PlayerAnimation = get_node_or_null("Animation")

func _physics_process(delta):
	var previous_position = global_position

	movement.move(delta)

	if animation != null:
		animation.update_motion(global_position - previous_position, delta)

	interaction.check_input()
