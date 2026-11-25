extends Node
var checks := 0

func _ready() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		get_tree().quit(1)

		return false

	checks += 1

	return true

func frames() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame

func finish(winner: int) -> void:
	HexManager.session.runtime.evaluate(
		(
			"var saved=Hex.dispatch({op:'save'}).game;saved.winner="
			+ str(winner)
			+ ";Hex.dispatch({op:'load',game:saved});"
		)
	)
	HexManager.request({"op": "view"})
	BattleManager.end_battle()
	await frames()

func run() -> void:
	var world = load("res://Scenes/TerrainTest.tscn").instantiate()

	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await get_tree().create_timer(0.3).timeout
	var area = SceneManager.current_scene
	var player = PlayerManager.get_player_node()
	var rival = area.get_node("Rival")

	if not check_setup(area, player, rival):
		return

	if not await check_ramp(player):
		return

	if not await check_fall(player):
		return

	if not await check_encounter(area, player, rival):
		return

	HexManager.battle_ui.queue_free()
	world.queue_free()
	await get_tree().create_timer(0.4).timeout
	print("Meadow elevation and rival encounter checks passed: ", checks)
	get_tree().quit(0)

func check_setup(area, player, rival) -> bool:
	if not check(
		area.scene_file_path.ends_with("MeadowTest.tscn"), "New entry point must load the meadow"
	):
		return false

	if not check(
		area.has_node("Market/Shopkeeper") and rival is Enemy,
		"Both character sprites must be placed"
	):
		return false

	if not check(
		area.get_node("Market/Shopkeeper") is Shopkeeper,
		"Shopkeeper must expose the shop interaction"
	):
		return false

	if not check(
		rival.encounter.hex_deck_id == "thornbound", "Rival must use a valid preconstructed deck"
	):
		return false

	if not check(
		player.global_position.z > 2.5 and player.is_on_floor(),
		"Player must spawn safely on the lower meadow"
	):
		return false

	return true

func check_ramp(player) -> bool:
	player.global_position = Vector3(0, 0.15, 1.25)
	player.velocity = Vector3.ZERO
	Input.action_press("ui_up")
	await get_tree().create_timer(0.7).timeout
	Input.action_release("ui_up")
	await frames()
	print("Ramp ascent position: ", player.global_position)

	if not check(
		player.global_position.z < -1.3 and player.global_position.y > 0.65,
		"Player must ascend the ramp onto the raised clearing"
	):
		return false

	Input.action_press("ui_down")
	await get_tree().create_timer(0.7).timeout
	Input.action_release("ui_down")
	await frames()

	if not check(
		player.global_position.z > 0.9 and player.global_position.y < 0.2 and player.is_on_floor(),
		"Player must descend the ramp and stay grounded"
	):
		return false

	return true

func check_fall(player) -> bool:
	player.global_position = Vector3(-2, 0.75, -2.4)
	player.velocity = Vector3.ZERO
	await get_tree().create_timer(0.15).timeout
	Input.action_press("ui_left")

	for frame in range(60):
		await get_tree().physics_frame

		if not player.is_on_floor():
			break

	var origin: Vector3 = player.global_position

	if not check(
		(
			not player.is_on_floor()
			and is_zero_approx(player.velocity.x)
			and is_zero_approx(player.velocity.z)
		),
		"Stepping off a ledge must immediately clear horizontal velocity"
	):
		return false

	Input.action_press("ui_up")
	await frames()

	if not check(
		(
			is_equal_approx(player.global_position.x, origin.x)
			and is_equal_approx(player.global_position.z, origin.z)
		),
		"Held input and air steering must not move a falling player sideways"
	):
		return false

	Input.action_release("ui_left")
	Input.action_release("ui_up")

	for frame in range(90):
		await get_tree().physics_frame

		if player.is_on_floor():
			break

	if not check(
		(
			player.is_on_floor()
			and player.global_position.y < 0.2
			and is_equal_approx(player.global_position.x, origin.x)
			and is_equal_approx(player.global_position.z, origin.z)
		),
		"Ledge fall must land straight below the departure point"
	):
		return false

	Input.action_press("ui_down")
	await frames()
	Input.action_release("ui_down")

	return check(
		player.global_position.z > origin.z + 0.02, "Horizontal control must resume after landing"
	)

func check_encounter(area, player, rival) -> bool:
	player.global_position = rival.global_position + Vector3(0, 0, 0.8)
	player.velocity = Vector3.ZERO
	BattleManager.last_battle_time = -100
	Input.action_press("ui_up")
	await get_tree().create_timer(0.2).timeout
	Input.action_release("ui_up")
	await frames()

	if not check(
		HexManager.is_encounter() and EnemyManager.active_enemy_id == "meadow-rival",
		"Actual rival collision must initiate the standard card battle"
	):
		return false

	if not check(
		SceneManager.current_scene == area and not player.visible,
		"Encounter must preserve the area and freeze the player"
	):
		return false

	rival.fled_reactivate_cooldown = 0.02
	await finish(1)
	player.global_position = Vector3(0, 0.75, -2)
	await get_tree().create_timer(0.06).timeout

	if not check(
		is_instance_valid(rival) and rival.active and player.visible,
		"Defeat must restore exploration and allow a later rival rematch"
	):
		return false

	BattleManager.last_battle_time = -100
	player.global_position = rival.global_position + Vector3(0, 0, 0.8)
	player.velocity = Vector3.ZERO
	Input.action_press("ui_up")
	await get_tree().create_timer(0.2).timeout
	Input.action_release("ui_up")
	await frames()

	if not check(HexManager.is_encounter(), "Rival must be challengeable again after defeat"):
		return false

	return await check_victory(player, rival)

func check_victory(player, rival) -> bool:
	var xp = PlayerManager.player.experience

	await finish(0)

	if not check(
		not is_instance_valid(rival) and PlayerManager.player.experience == xp + 20,
		"Victory must remove the rival and award XP once"
	):
		return false

	if not check(
		not InteractionHandler.is_blocked() and player.visible,
		"Battle completion must restore player control"
	):
		return false

	return true
