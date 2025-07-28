extends CharacterBody3D

@onready var movement = $Movement
@onready var interaction = $Interact

func _physics_process(delta):
	movement.move(delta)
	interaction.check_input()
