extends Node

var nearby_targets: Array = []
var current_target: Node = null
var last_input_vector: Vector3 = Vector3.FORWARD
var can_interact := true

@export var interact_input := "Interact"
@export var interact_cooldown := 1.0

@onready var player = get_parent()

func check_input():
	if not can_interact or not current_target or InteractionHandler.is_blocked():
		return

	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed(interact_input):
		# Run interaction and lock further input
		can_interact = false
		current_target.interact()

		# Wait for interaction blockers to clear (dialog, cutscene, etc.)
		await _wait_for_unblocked()
		await get_tree().create_timer(interact_cooldown).timeout
		can_interact = true

func _wait_for_unblocked():
	while InteractionHandler.is_blocked():
		await get_tree().process_frame

func update_last_input(input_vector: Vector2):
	if input_vector.length() > 0.1:
		last_input_vector = Vector3(input_vector.x, 0, input_vector.y).normalized()

func add_target(target: Node):
	if not nearby_targets.has(target):
		nearby_targets.append(target)

func remove_target(target: Node):
	nearby_targets.erase(target)

func _process(_delta):
	_update_best_target()

func _update_best_target():
	var best_score := -INF
	var best_target: Node = null

	for target in nearby_targets:
		if not is_instance_valid(target):
			continue

		var to_target = (target.global_transform.origin - player.global_transform.origin)
		var distance_score = 1.0 / (to_target.length() + 0.01)  # Prevent div by zero
		var direction_score = to_target.normalized().dot(last_input_vector)
		var total_score = distance_score + direction_score

		if total_score > best_score:
			best_score = total_score
			best_target = target

	# Update visibility
	if current_target and current_target != best_target:
		current_target.hide_action_bubble()

	current_target = best_target

	if current_target:
		current_target.show_action_bubble()
