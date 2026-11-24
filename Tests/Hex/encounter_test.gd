extends Node
var checks := 0

func check(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		get_tree().quit(1)

		return false

	checks += 1

	return true

func frames():
	await get_tree().process_frame
	await get_tree().process_frame

func fixture(id: String) -> Enemy:
	var enemy := Enemy.new()

	enemy.id = id
	enemy.fled_reactivate_cooldown = 0.001
	enemy.encounter = EncounterData.new()
	var resource := EnemyResource.new()

	resource.name = "Encounter test"
	resource.xp_reward = 7
	enemy.encounter.enemies.append(resource)
	SceneManager.current_scene.add_child(enemy)
	BattleManager.last_battle_time = -100

	return enemy

func finish(winner: int):
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

func _ready():
	call_deferred("run")

func run():
	var world = load("res://Scenes/Root.tscn").instantiate()

	get_tree().root.add_child(world)
	get_tree().current_scene = world

	for i in range(12):
		await get_tree().process_frame

	HexManager.ensure_match()
	HexManager.session.request({"op": "new", "seed": 123})
	var practice := HexManager.save_hex()
	var original_scene = SceneManager.current_scene
	var player = PlayerManager.get_player_node()
	var original_position: Vector3 = player.global_position
	var original_scale: int = get_window().content_scale_mode
	var xp: int = PlayerManager.player.experience
	var enemy := fixture("hex-victory-test")

	enemy._on_body_entered(player)
	await frames()
	var hex: HexBattleUI = HexManager.battle_ui

	if not check(
		HexManager.is_encounter() and BattleManager.hex_encounter_active,
		"World collision did not start Hex"
	):
		return

	if not check(
		SceneManager.current_scene == original_scene and BattleManager.battle_ui == null,
		"Encounter changed world or opened legacy battle UI"
	):
		return

	if not check(
		not player.visible and not player.is_physics_processing() and player.collision_layer == 0,
		"World player not frozen"
	):
		return

	await frames()

	if not check(
		hex.battle.board.size.x <= hex.battle.board.get_parent().size.x + 1,
		"Battlefield overflows horizontally"
	):
		return

	var image = hex.battle.Card.art("LT-001").get_image()

	if not check(
		image.get_width() == 1024 and image.has_mipmaps(),
		"Full-size mipmapped card texture missing"
	):
		return

	if not check(
		hex.visible and hex.battle.get_viewport() == get_viewport(),
		"Battle must use main viewport at native resolution"
	):
		return

	if not check(
		get_window().content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS,
		"Hex should render UI at window resolution"
	):
		return

	HexManager.request({"op": "new", "seed": 99})
	MenuManager.set_menu(true, MenuTabs.Tab.OPTIONS)
	MenuManager.hide_menu()

	if not check(
		hex.visible and HexManager.is_encounter(), "Menu/new-game bypassed active encounter"
	):
		return

	if not check(
		UIManager.handle_cancel() and hex.battle.modal != null, "Escape must confirm encounter exit"
	):
		return

	UIManager.handle_cancel()
	var other := fixture("hex-other-test")

	EnemyManager.start_battle_from_enemy(other)

	if not check(
		EnemyManager.active_enemy_id == enemy.id and other.active,
		"Second enemy overwrote active encounter"
	):
		return

	await finish(0)

	if not check(not is_instance_valid(enemy), "Victory did not remove defeated world enemy"):
		return

	if not check(PlayerManager.player.experience == xp + 7, "Victory XP missing or duplicated"):
		return

	if not check(
		not HexManager.is_encounter() and HexManager.save_hex().game.serial == practice.game.serial,
		"Practice match not restored"
	):
		return

	if not check(
		(
			player.visible
			and player.is_physics_processing()
			and player.global_position == original_position
			and not InteractionHandler.is_blocked()
		),
		"World controls or position not restored"
	):
		return

	if not check(
		get_window().content_scale_mode == original_scale, "RPG rendering mode not restored"
	):
		return

	BattleManager.end_battle()

	if not check(PlayerManager.player.experience == xp + 7, "Repeated completion granted XP"):
		return

	other.queue_free()

	for result in [1, -1]:
		var loser := fixture("hex-loss-test" + str(result))

		EnemyManager.start_battle_from_enemy(loser)
		await frames()
		await finish(result)
		await get_tree().create_timer(0.02).timeout

		if not check(
			is_instance_valid(loser) and loser.active and PlayerManager.player.experience == xp + 7,
			"Defeat/draw must keep enemy without XP"
		):
			return

		loser.queue_free()

	var resumed := fixture("hex-save-test")

	EnemyManager.start_battle_from_enemy(resumed)
	await frames()
	var encounter := HexManager.save_hex()

	HexManager.load_hex(practice)
	await frames()

	if not check(
		not BattleManager.hex_encounter_active, "Practice load retained encounter binding"
	):
		return

	HexManager.load_hex(encounter)
	await frames()

	if not check(
		(
			HexManager.is_encounter()
			and EnemyManager.active_enemy_id == resumed.id
			and not player.visible
		),
		"Saved encounter did not rebind world enemy"
	):
		return

	HexManager.load_hex({})
	await frames()

	if not check(
		not HexManager.is_encounter() and not BattleManager.hex_encounter_active,
		"Legacy save kept old encounter"
	):
		return

	resumed.queue_free()
	print("Hex encounter and rendering checks passed: ", checks)

	if is_instance_valid(MenuManager.menu_ui):
		MenuManager.menu_ui.queue_free()

	HexManager.battle_ui.queue_free()
	world.queue_free()
	await get_tree().create_timer(0.4).timeout
	get_tree().quit()
