extends CharacterBody3D
class_name AllyController

@export var follow_distance: float = 2.0
@export var speed: float = 4.0
@export var acceleration: float = 10.0

var player: Node3D = null

func _ready():
	# Find the player in the "Player" group
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
	else:
		push_error("No player found in 'Player' group. Ally cannot follow.")

func _physics_process(delta):
	if not player:
		return

	var to_player = player.global_transform.origin - global_transform.origin
	var distance = to_player.length()

	if distance > follow_distance:
		# Move toward player
		var direction = to_player.normalized()
		velocity = velocity.lerp(direction * speed, acceleration * delta)
	else:
		# Slow down when close enough
		velocity = velocity.lerp(Vector3.ZERO, acceleration * delta)

	move_and_slide()

	# Face movement direction
	if velocity.length_squared() > 0.01:
		look_at(global_transform.origin + velocity, Vector3.UP)
