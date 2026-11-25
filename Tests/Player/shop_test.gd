extends Node
var checks := 0
var world: Node
var ui: UIBase

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

func run() -> void:
	ShopManager.save_path = "user://shop-regression.json"
	ShopManager.load_shop({"version": 1, "collection": {}})
	world = load("res://Scenes/TerrainTest.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await get_tree().create_timer(0.3).timeout

	if not await check_interaction():
		return

	if not check_stock():
		return

	if not await check_reveal():
		return

	if not await check_persistence():
		return

	if not await check_lifecycle():
		return

	ShopManager.close_shop()
	ShopManager.shop_ui.queue_free()

	if is_instance_valid(HexManager.battle_ui):
		HexManager.battle_ui.queue_free()

	world.queue_free()
	await get_tree().create_timer(0.4).timeout
	print("Free shop interaction, stock, reveal and persistence checks passed: ", checks)
	get_tree().quit(0)

func check_interaction() -> bool:
	var player = PlayerManager.get_player_node()
	var vendor = SceneManager.current_scene.get_node("Market/Shopkeeper")

	player.global_position = vendor.global_position + Vector3(0, 0, 0.4)
	await get_tree().create_timer(0.1).timeout

	if not check(
		player.interaction.nearby_targets.has(vendor),
		"Shopkeeper proximity must register with existing player interaction"
	):
		return false

	Input.action_press("Interact")
	await frames()
	Input.action_release("Interact")
	ui = ShopManager.shop_ui
	await get_tree().process_frame
	await get_tree().process_frame

	if not check(
		ShopManager.is_open() and UIManager.top() == ui and InteractionHandler.is_blocked(),
		"Interact must open a modal shop and block movement"
	):
		return false

	if not check(not HexManager.initialized, "Browsing the shop must keep the battle engine lazy"):
		return false

	if not check(ui.grid.get_child_count() == 3, "Shop must expose all three booster sets"):
		return false

	if not check(
		ui.grid.get_parent().size.y > 160,
		"Shop shelf must remain visible below the header and filters"
	):
		return false

	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shop-boosters.png")

	return true

func check_stock() -> bool:
	var deck = HexManager.active_deck.duplicate()
	var first = ShopManager.buy_single("LT-001")

	ShopManager.buy_single("LT-001")

	if not check(
		first.ok and ShopManager.quantity("LT-001") == 2,
		"Free singles must add counted copies without currency"
	):
		return false

	if not check(
		ShopManager.return_card("LT-001").ok and ShopManager.quantity("LT-001") == 1,
		"Returning a copy must update collection quantities"
	):
		return false

	if not check(not ShopManager.save_shop().has("coins"), "Test shop must not introduce currency"):
		return false

	return check_boosters() and check_prints(deck)

func check_boosters() -> bool:
	for set_id in ShopManager.SETS:
		var result = ShopManager.buy_booster(set_id)

		if not check(result.ok and result.cards.size() == 5, "Booster must contain five cards"):
			return false

		var counts = {"Common": 0, "Uncommon": 0, "rare": 0}

		for id in result.cards:
			var card = ShopManager.card_data(id)

			if not check(
				card.set == set_id and ShopManager.quantity(id) > 0,
				"Booster contents must belong to the chosen set and be saved"
			):
				return false

			counts[card.rarity if card.rarity in ["Common", "Uncommon"] else "rare"] += 1

		if not check(
			counts.Common == 3 and counts.Uncommon == 1 and counts.rare == 1,
			"Boosters must guarantee three Commons, one Uncommon and one Rare or better"
		):
			return false

	return true

func check_prints(deck: Array) -> bool:
	for id in ["LT-001-FA", "LT-001-IR"]:
		if not check(
			ShopManager.buy_single(id).ok and ShopManager.quantity(id) == 1,
			"Cosmetic print must be available as free stock"
		):
			return false

		if not check(
			ShopManager.card_data(id).rules == ShopManager.card_data("LT-001").rules,
			"Cosmetic prints must retain identical card rules"
		):
			return false

	var before = ShopManager.save_shop()

	if not check(
		(
			not ShopManager.buy_single("invalid").ok
			and not ShopManager.buy_booster("invalid").ok
			and before == ShopManager.save_shop()
		),
		"Invalid requests must not mutate the collection"
	):
		return false

	if not check(deck == HexManager.active_deck, "Shop activity must not change battle decks"):
		return false

	return true

func check_reveal() -> bool:
	ui._open_pack("shattered-arcana")

	if not check(
		ui.receipt.visible and ui.receipt_cards.get_child_count() == 5,
		"Booster opening must reveal all five cards"
	):
		return false

	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shop-reveal.png")

	UIManager.handle_cancel()

	if not check(
		ui.visible and not ui.receipt.visible,
		"First Escape must dismiss the reveal without closing the shop"
	):
		return false

	ui.tabs.current_tab = 1
	ui.print_filter.selected = 2
	ui.search.text = "Loyal Pup"
	ui._refresh()

	if not check(
		ui._entries() == ["LT-001-IR"], "Search and print filters must select the requested card"
	):
		return false

	UIManager.handle_cancel()

	return check(
		not ShopManager.is_open() and not InteractionHandler.is_blocked(),
		"Closing shop must release world movement"
	)

func check_persistence() -> bool:
	var before = ShopManager.save_shop()
	var path = ShopManager.save_path

	ShopManager.save_path = "user://missing-directory/shop.json"

	if not check(
		not ShopManager.buy_single("LT-002").ok and before == ShopManager.save_shop(),
		"Failed persistence must roll back free card grants"
	):
		return false

	ShopManager.save_path = path
	var invalid = {"version": 1, "collection": {"LT-001": -1}}

	if not check(
		not ShopManager.load_shop(invalid) and before == ShopManager.save_shop(),
		"Invalid saved counts must not damage the collection"
	):
		return false

	var clone = load("res://Scripts/Managers/ShopManager.gd").new()

	clone.save_path = path
	add_child(clone)

	if not check(
		clone.save_shop() == before, "Shop collection must restore after restarting the manager"
	):
		return false

	clone.queue_free()
	GameStateManager.save_game_to_file("user://shop-world.dat")
	ShopManager.buy_single("LT-002")
	await GameStateManager.load_game_from_file("user://shop-world.dat")

	return check(
		ShopManager.save_shop() == before, "World saves must restore the matching shop collection"
	)

func check_lifecycle() -> bool:
	ShopManager.open_shop()
	MenuManager.set_menu(true, MenuTabs.Tab.HEX)

	if not check(
		not is_instance_valid(MenuManager.menu_ui),
		"Menu hotkeys must not stack a deck builder above the shop"
	):
		return false

	HexManager.open_battle()

	if not check(
		not ShopManager.is_open() and HexManager.is_battle_open(),
		"Opening a battle must close the shop"
	):
		return false

	var before = ShopManager.save_shop()

	if not check(
		(
			not ShopManager.open_shop()
			and not ShopManager.buy_single("LT-001").ok
			and before == ShopManager.save_shop()
		),
		"Battles must block shopping and collection mutation"
	):
		return false

	HexManager.close_battle(true)
	ShopManager.open_shop()
	await SceneManager.load_scene(
		"res://Scenes/Environments/MeadowTest.tscn", false, false, "PlayerSpawn"
	)

	return check(
		not ShopManager.is_open() and not InteractionHandler.is_blocked(),
		"Scene changes must close the shop and release its input block"
	)
