class_name PlayerAnimation
extends Node
## Animate actual travel so walking into walls or opening menus returns to idle.
@export var minimum_motion := 0.015
var facing := "down"
@onready var player: CharacterBody3D = get_parent()
@onready var sprite: AnimatedSprite3D = player.get_node("Sprite")

func update_motion(displacement: Vector3, delta: float) -> void:
	var velocity = displacement / maxf(delta, 0.0001)

	velocity.y = 0
	var moving = velocity.length() > minimum_motion and not InteractionHandler.is_blocked()

	if moving:
		var camera = get_viewport().get_camera_3d()
		var right = Vector3.RIGHT
		var up = Vector3.FORWARD

		if camera != null:
			right = camera.global_basis.x
			up = camera.global_basis.y
			right.y = 0
			up.y = 0
			right = right.normalized()
			up = up.normalized()

		var direction = Vector2(velocity.dot(right), -velocity.dot(up))

		if absf(direction.x) > absf(direction.y):
			facing = "right" if direction.x > 0 else "left"
		else:
			facing = "down" if direction.y > 0 else "up"

	var animation = ("walk_" if moving else "idle_") + facing

	if sprite.animation != animation or not sprite.is_playing():
		sprite.play(animation)

	var movement = player.get_node("Movement")

	sprite.speed_scale = (
		clampf(velocity.length() / maxf(0.1, movement.speed), 0.5, 1.8) if moving else 1.0
	)
