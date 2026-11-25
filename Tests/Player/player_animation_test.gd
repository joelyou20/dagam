extends SceneTree
var checks := 0
var player: CharacterBody3D

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		quit(1)

		return

	checks += 1

func run() -> void:
	var world = Node3D.new()

	root.add_child(world)
	var floor_body = StaticBody3D.new()
	var floor_shape = CollisionShape3D.new()
	var floor_box = BoxShape3D.new()

	floor_box.size = Vector3(30, 0.2, 30)
	floor_shape.shape = floor_box
	floor_body.position.y = -0.1
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	player = load("res://Scenes/Player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	await process_frame
	var sprite: AnimatedSprite3D = player.get_node("Sprite")
	var animator = player.get_node("Animation")
	var frames = sprite.sprite_frames

	check(
		sprite.billboard == BaseMaterial3D.BILLBOARD_ENABLED,
		"Player must remain a billboard in the existing 3D world"
	)
	check(
		sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST,
		"Pixel art must use nearest filtering"
	)
	check(frames.get_animation_names().size() == 8, "Four facings need idle and walking loops")

	for facing in ["down", "left", "right", "up"]:
		for action in ["idle", "walk"]:
			var name = action + "_" + facing

			check(frames.has_animation(name), "Missing animation: " + name)
			check(frames.get_frame_count(name) == 8, "Expected eight frames per loop")
			check(frames.get_animation_loop(name), "Movement and idle must loop")

			for index in range(8):
				var texture = frames.get_frame_texture(name, index) as AtlasTexture

				check(
					texture != null and texture.region.has_area(),
					"Frames must use valid atlas regions"
				)
				check(
					Rect2(Vector2.ZERO, texture.atlas.get_size()).encloses(texture.region),
					"Frame must fit inside source atlas"
				)

	var directions = {
		"right": Vector3.RIGHT, "left": Vector3.LEFT, "up": Vector3.FORWARD, "down": Vector3.BACK
	}

	for facing in directions:
		animator.update_motion(directions[facing] * 0.5, 0.1)
		check(
			sprite.animation == "walk_" + facing,
			"Travel must select correct screen-facing animation"
		)
		animator.update_motion(Vector3.ZERO, 0.1)
		check(sprite.animation == "idle_" + facing, "Stopping must keep last facing")

	animator.update_motion(Vector3.RIGHT * 0.5, 0.1)
	var initial_frame = sprite.frame

	await create_timer(0.25).timeout
	check(sprite.frame != initial_frame, "Walk frames must advance over time")
	root.get_node("InteractionHandler").block("animation-test")
	animator.update_motion(Vector3.RIGHT, 0.1)
	check(sprite.animation == "idle_right", "Interaction blockers must stop walking animation")
	root.get_node("InteractionHandler").unblock("animation-test")
	player.set_physics_process(true)
	Input.action_press("ui_left")
	await physics_frame
	await physics_frame
	await physics_frame
	check(
		sprite.animation == "walk_left", "Real input must drive animation through PlayerController"
	)
	Input.action_release("ui_left")
	await physics_frame
	await physics_frame
	check(sprite.animation == "idle_left", "Releasing movement must immediately idle")

	var movement = player.get_node("Movement")

	for diagonal in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
		var cardinal: Vector2 = movement._cardinal_input(diagonal)

		check(
			is_zero_approx(cardinal.x) != is_zero_approx(cardinal.y),
			"Diagonal input must resolve to exactly one axis"
		)
		check(is_equal_approx(cardinal.length(), 1), "Cardinal movement must preserve normal speed")

	check(
		movement._cardinal_input(Vector2(1, -1), false, true) == Vector2.UP,
		"New vertical key must take priority"
	)
	check(
		movement._cardinal_input(Vector2(1, -1)) == Vector2.UP,
		"Held diagonal must retain its chosen axis"
	)
	check(
		movement._cardinal_input(Vector2.RIGHT) == Vector2.RIGHT,
		"Releasing priority key must resume the held direction"
	)
	check(
		movement._cardinal_input(Vector2(1, -1), true, false) == Vector2.RIGHT,
		"New horizontal key must take priority"
	)
	check(movement._cardinal_input(Vector2.ZERO) == Vector2.ZERO, "Opposite keys must cancel")
	check(
		movement._cardinal_input(Vector2(0.2, -0.8)) == Vector2.UP,
		"Analogue movement must use the dominant axis"
	)

	Input.action_press("ui_right")
	await physics_frame
	await physics_frame
	Input.action_press("ui_up")
	await physics_frame
	await physics_frame
	await physics_frame
	check(
		is_zero_approx(player.velocity.x) and player.velocity.z < 0,
		"Two real held keys must not move diagonally"
	)
	check(sprite.animation == "walk_up", "Animation must follow the chosen cardinal direction")
	check(
		movement.input_direction == Vector2.UP, "Camera lead must receive the chosen cardinal input"
	)
	Input.action_release("ui_up")
	await physics_frame
	await physics_frame
	check(
		player.velocity.x > 0 and is_zero_approx(player.velocity.z),
		"Releasing newest key must resume the older held key"
	)
	Input.action_release("ui_right")
	await physics_frame
	await physics_frame

	# A physical wall must stop animation even while movement input is held.
	var wall = StaticBody3D.new()
	var collider = CollisionShape3D.new()
	var box = BoxShape3D.new()

	box.size = Vector3(0.1, 2, 2)
	collider.shape = box
	wall.add_child(collider)
	world.add_child(wall)
	wall.global_position = player.global_position + Vector3(0.35, 0, 0)
	Input.action_press("ui_right")
	await create_timer(0.4).timeout
	check(sprite.animation == "idle_right", "Pushing against a wall must not keep walking in place")
	Input.action_release("ui_right")
	world.queue_free()
	await process_frame
	print("Player movement animation checks passed: ", checks)
	quit(0)
