extends Node

var nearby_targets: Array = []
var current_target: Interactable = null
var last_input_vector: Vector3 = Vector3.FORWARD
var can_interact := true

@export var interact_input := "Interact"
@export var interact_cooldown := 1.0

@onready var player = get_parent()

func check_input():
	if not can_interact or not current_target or InteractionHandler.is_blocked():
		return

	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed(interact_input):
		can_interact = false
		current_target.interact()

		await _wait_for_unblocked()
		await get_tree().create_timer(interact_cooldown).timeout
		can_interact = true

func _wait_for_unblocked():
	while InteractionHandler.is_blocked():
		await get_tree().process_frame

func update_last_input(input_vector: Vector2):
	if input_vector.length() > 0.1:
		last_input_vector = Vector3(input_vector.x, 0, input_vector.y).normalized()

func add_target(target: Interactable):
	if not nearby_targets.has(target):
		nearby_targets.append(target)

func remove_target(target: Interactable):
	nearby_targets.erase(target)

func _process(_delta):
	_update_best_target()

func _update_best_target():
	var best_score := -INF
	var best_target: Interactable = null

	for target in nearby_targets:
		if not is_instance_valid(target) or not target is Interactable:
			continue
		if not target.is_interactable():
			continue

		var score = target.get_interaction_score(player.global_transform.origin, last_input_vector)
		if score > best_score:
			best_score = score
			best_target = target

	if current_target and current_target != best_target:
		current_target.hide_action_bubble()

	current_target = best_target

	if current_target:
		current_target.show_action_bubble()
