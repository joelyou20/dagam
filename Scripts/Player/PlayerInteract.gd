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
	if target and not nearby_targets.has(target):
		nearby_targets.append(target)
		if not target.tree_exited.is_connected(_on_target_tree_exited):
			target.tree_exited.connect(_on_target_tree_exited.bind(target)) # Godot 4

func remove_target(target: Interactable):
	if target:
		if target.tree_exited.is_connected(_on_target_tree_exited):
			target.tree_exited.disconnect(_on_target_tree_exited)
	nearby_targets.erase(target)

func _on_target_tree_exited(target: Interactable):
	nearby_targets.erase(target)
	if current_target == target:
		current_target = null
	
func _exit_tree():
	# Hide bubble safely and clear refs when this manager is going away
	if is_instance_valid(current_target):
		current_target.hide_action_bubble()
	current_target = null

	# Disconnect signals and clear the list to avoid “previously freed” refs
	for t in nearby_targets:
		if is_instance_valid(t) and t.tree_exited.is_connected(_on_target_tree_exited):
			t.tree_exited.disconnect(_on_target_tree_exited)
	nearby_targets.clear()

func _process(_delta):
	_update_best_target()

func _update_best_target():
	var best_score := -INF
	var best_target: Interactable = null

	# prune invalids as you go (iterate backwards when removing)
	for i in range(nearby_targets.size() - 1, -1, -1):
		var t = nearby_targets[i]
		if not is_instance_valid(t) or not (t is Interactable):
			nearby_targets.remove_at(i)
			continue
		if not t.is_interactable():
			continue

		var s = t.get_interaction_score(player.global_transform.origin, last_input_vector)
		if s > best_score:
			best_score = s
			best_target = t

	if is_instance_valid(current_target) and current_target != best_target:
		current_target.hide_action_bubble()

	current_target = best_target

	if is_instance_valid(current_target):
		current_target.show_action_bubble()
