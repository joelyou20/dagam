extends Node

signal scene_loaded  # Add this signal

@onready var fade_scene := preload("res://Scenes/FadeScene.tscn")
@onready var scene_root: Node = get_tree().get_root().get_node("World/SceneRoot")
var current_scene: Node = null
var fade_layer: FadeLayer

func load_scene(path: String, should_fade_out: bool = true, should_fade_in: bool = true, spawn_point_name: String = "", fade_speed: float = 1.0) -> void:
	# Initialize fade layer if it doesn't exist or color_rect is null
	if not fade_layer or not fade_layer.color_rect:
		await initialize_fade_layer()
	
	if should_fade_out:
		# Now we can safely use the fade layer
		fade_layer.fade_out(fade_speed)
		await fade_layer.fade_completed
	
	if current_scene:
		current_scene.queue_free()
	
	# Load the new scene
	var new_scene = load(path).instantiate()
	scene_root.add_child.call_deferred(new_scene)
	current_scene = new_scene
	
	call_deferred("_position_player", new_scene, spawn_point_name)
	
	# Wait for scene to be added and positioned, then emit signal BEFORE fade-in
	await get_tree().process_frame
	await get_tree().process_frame
	emit_signal("scene_loaded")
	
	if should_fade_in:
		# Optional: Wait a bit then fade back in
		fade_layer.fade_in(fade_speed)
		await fade_layer.fade_completed

func initialize_fade_layer():
	fade_layer = fade_scene.instantiate() as FadeLayer
	get_tree().get_root().add_child.call_deferred(fade_layer)
	
	# Wait for the fade layer to be ready
	await get_tree().process_frame
	
	# Double check that it's properly initialized
	if not fade_layer.color_rect:
		await get_tree().process_frame

func _position_player(new_scene: Node, spawn_point_name: String):
	var player = get_tree().get_nodes_in_group("Player")[0]
	var spawn_point = new_scene.get_node_or_null(spawn_point_name)
	if player and spawn_point:
		# Check both the spawn point and player transforms
		if spawn_point.global_transform.basis.determinant() == 0:
			push_error("Spawn point has a zero-scale basis! Cannot apply transform.")
			return
		
		if player.global_transform.basis.determinant() == 0:
			push_error("Player has a zero-scale basis! Resetting to identity.")
			# Reset player's basis to identity before positioning
			player.global_transform = Transform3D(Basis(), spawn_point.global_transform.origin)
			return
		
		# Only update the position, preserve the player's rotation and scale
		var new_transform = player.global_transform
		new_transform.origin = spawn_point.global_transform.origin
		player.global_transform = new_transform

func set_black_screen():
	# Initialize fade layer if it doesn't exist or color_rect is null
	if not fade_layer or not fade_layer.color_rect:
		await initialize_fade_layer()
	
	fade_layer.instant_fade_out()
