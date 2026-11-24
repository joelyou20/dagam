extends Node

var checks := 0
var world: Node

func _ready():
	call_deferred("run")

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

func farmer_nodes() -> Array:
	return get_tree().get_nodes_in_group("NPC").filter(
		func(n): return n is NPC and n.id == "farmer"
	)

func run():
	world = load("res://Scenes/Root.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world

	for i in range(15):
		await get_tree().process_frame

	MenuManager.set_menu(true, MenuTabs.Tab.ADVENTURE)
	await frames()
	var menu = MenuManager.menu_ui

	if not check(
		menu.content_uis.keys().size() == 5 and menu.content_uis.has("Journal"),
		"Exploration navigation was not migrated"
	):
		return

	if not check(
		not menu.has_node("VBoxContainer/MenuTopNav/HBoxContainer/EquipmentButton"),
		"Equipment navigation remains active"
	):
		return

	menu.open_root(MenuTabs.Tab.JOURNAL)
	menu.open_root(MenuTabs.Tab.INVENTORY)
	menu.open_root(MenuTabs.Tab.HEX)
	MenuManager.hide_menu(true)

	if not check(
		not InteractionHandler.is_blocked(), "Exploration pages did not release world input"
	):
		return

	GameStateManager.save_game_to_file("user://before-farmer.dat")

	if not check(farmer_nodes().size() == 1, "Farmer NPC missing before recruitment"):
		return

	var inventory_before = InventoryManager.save_inventory()
	var dialog = load("res://Resources/Dialog/npc_farmer.tres")
	var entry = dialog.entries.filter(func(item): return item.id == "kick_again")[0]

	for action in entry.actions:
		action.execute()

	await frames()

	if not check(
		CompanionManager.has_companion("farmer") and farmer_nodes().is_empty(),
		"Actual Farmer dialogue action no longer recruits/removes NPC"
	):
		return

	for action in entry.actions:
		action.execute()

	await frames()

	if not check(CompanionManager.members.size() == 1, "Repeated recruitment duplicated Farmer"):
		return

	if not check(
		InventoryManager.save_inventory() == inventory_before,
		"Recruitment silently awarded old starting equipment"
	):
		return

	if not check(
		PartyManager.get_member_by_id("farmer") != null, "Legacy recruitment adapter broke"
	):
		return

	QuestManager.accept_quest(QuestData.QuestName.INTRO_QUEST)
	FlagManager.set_flag(FlagData.FlagName.KICKED_GREGS_DOG)
	QuestManager.validate_active_quest_requirements()

	if not check(
		"INTRO_QUEST" in QuestManager.completed_quests, "Existing test quest cannot complete"
	):
		return

	var player = PlayerManager.player
	var farmer = PartyManager.get_member_by_id("farmer")
	var companion_xp = farmer.experience
	var original_attack = player.physical_attack

	player.experience = 90
	player.xp_to_next_level = 100
	player.level = 1
	player.xp_growth_rate = 1.2
	PlayerManager.add_xp(20)

	if not check(
		player.level == 2 and player.experience == 10 and player.xp_to_next_level == 120,
		"Solo duelist level progression failed"
	):
		return

	if not check(
		farmer.experience == companion_xp and player.physical_attack == original_attack,
		"Companions or RPG stats changed from duelist XP"
	):
		return

	var enemy = Enemy.new()

	enemy.id = "tcg-xp-probe"
	enemy.encounter = EncounterData.new()
	var resource = EnemyResource.new()

	resource.name = "TCG test opponent"
	resource.xp_reward = 9
	enemy.encounter.enemies.append(resource)
	SceneManager.current_scene.add_child(enemy)
	BattleManager.last_battle_time = -100
	EnemyManager.start_battle_from_enemy(enemy)
	await frames()
	(
		HexManager
		. session
		. runtime
		. evaluate(
			"var saved=Hex.dispatch({op:'save'}).game;saved.winner=0;Hex.dispatch({op:'load',game:saved});"
		)
	)
	HexManager.request({"op": "view"})
	BattleManager.end_battle()
	await frames()

	if not check(
		player.experience == 19 and farmer.experience == companion_xp,
		"Encounter XP was split with Farmer"
	):
		return

	if not check(
		UnitManager.get_all_units().is_empty() and TurnOrderManager.turn_order_queue.is_empty(),
		"Old RPG combat activated"
	):
		return

	var potion = load("res://Resources/Items/potion.tres")

	InventoryManager.add_item(potion, 2)
	player.current_hp = 1

	if not check(
		(
			InventoryManager.use_item(potion)
			and (
				(
					InventoryManager
					. get_items()
					. filter(func(s): return s.item.id == potion.id)[0]
					. quantity
				)
				== 1
			)
		),
		"Exploration inventory use failed"
	):
		return

	var sword = load("res://Resources/Items/Equipment/sword.tres")
	var equipment_before = player.main_weapon_equipment

	EquipmentManager.equip_item(player, sword)

	if not check(
		(
			player.main_weapon_equipment == equipment_before
			and PartyManager.get_ally_equipment(farmer).is_empty()
		),
		"Retired equipment effects are still active"
	):
		return

	GameStateManager.save_game_to_file("user://with-farmer.dat")
	var expected_bag = InventoryManager.save_inventory()

	await GameStateManager.load_game_from_file("user://before-farmer.dat")
	await frames()

	if not check(
		not CompanionManager.has_companion("farmer") and farmer_nodes().size() == 1,
		"Loading an earlier checkpoint did not restore Farmer"
	):
		return

	await GameStateManager.load_game_from_file("user://with-farmer.dat")
	await frames()

	if not check(
		CompanionManager.has_companion("farmer") and farmer_nodes().is_empty(),
		"Recruitment was lost on save/load"
	):
		return

	if not check(
		InventoryManager.save_inventory() == expected_bag,
		"Inventory changed across migration save/load"
	):
		return

	var file = FileAccess.open("user://with-farmer.dat", FileAccess.READ)
	var old_save = file.get_var()

	file.close()
	old_save.erase("companions")
	file = FileAccess.open("user://legacy-party.dat", FileAccess.WRITE)
	file.store_var(old_save)
	file.close()
	await GameStateManager.load_game_from_file("user://legacy-party.dat")

	if not check(
		CompanionManager.has_companion("farmer"), "Legacy party-key saves did not migrate"
	):
		return

	menu.open_root(MenuTabs.Tab.JOURNAL)
	await frames()

	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.5).timeout
		get_tree().root.get_texture().get_image().save_png("user://tcg-journal.png")
		menu.open_root(MenuTabs.Tab.ADVENTURE)
		await frames()
		get_tree().root.get_texture().get_image().save_png("user://tcg-adventure.png")

	print("RPG-TCG navigation, Farmer and save compatibility checks passed: ", checks)
	MenuManager.hide_menu(true)

	if is_instance_valid(HexManager.battle_ui):
		HexManager.battle_ui.queue_free()

	menu.queue_free()
	world.queue_free()
	await get_tree().create_timer(0.4).timeout
	get_tree().quit()
