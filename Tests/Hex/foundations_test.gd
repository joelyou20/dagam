extends Node
var checks := 0
var cards: Array
var world: Node

func _ready() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		get_tree().quit(1)

		return false

	checks += 1

	return true

func run() -> void:
	cards = HexPreviewCatalog.cards()

	if not check_metadata():
		return

	if not check_artwork():
		return

	world = load("res://Scenes/TerrainTest.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await get_tree().create_timer(0.3).timeout

	if not await check_decks():
		return

	if not await check_shop():
		return

	ShopManager.close_shop()
	ShopManager.shop_ui.queue_free()
	MenuManager.menu_ui.queue_free()
	world.queue_free()
	await get_tree().create_timer(0.3).timeout
	print("Foundations preview metadata, artwork and non-playable catalog checks passed: ", checks)
	get_tree().quit(0)

func check_metadata() -> bool:
	if not check(
		cards.size() == 26 and not HexManager.initialized,
		"Preview catalog must contain 26 cards without starting the battle engine"
	):
		return false

	var ids = {}
	var pairs = {}

	for card in cards:
		ids[card.id] = true

		if not check(
			card.preview_only and card.set == "foundations",
			"Every Foundations card must be explicitly preview-only"
		):
			return false

		if int(card.number) <= 21:
			if not check(
				card.rules.is_empty() and card.cost.is_empty(),
				"Basic and basic dual Planes must have no rules or invented costs"
			):
				return false

		if int(card.number) in range(7, 22):
			var terrain: Array = card.terrain_types.duplicate()

			terrain.sort()
			pairs["/".join(terrain)] = true

	if not check(
		ids.size() == 26 and pairs.size() == 15,
		"All cards and all fifteen dual-terrain pairings must be distinct"
	):
		return false

	if not check(
		(
			cards[21].cost == {"Water": 1.0, "Earth": 1.0}
			and cards[22].terrain_types == ["Light"]
			and cards[23].cost == {"Earth": 1.0, "Fire": 1.0}
			and cards[25].cost == {"Fire": 2.0}
		),
		"Specified costs and Wall of Light terrain must be preserved"
	):
		return false

	return check(
		cards[24].generated_only and cards[23].card_type == "Spell",
		"Volcanic Vent must be identified as generated and Erupt as a Spell"
	)

func check_artwork() -> bool:
	var hashes = {}

	for card in cards:
		var source = "res://Artwork/Foundations/art/" + card.id + ".png"

		if not check(FileAccess.file_exists(source), "Missing original illustration: " + card.id):
			return false

		hashes[FileAccess.get_sha256(source)] = true

		for suffix in ["", "-FA"]:
			var path = "res://Assets/Hex/cards/" + card.id + suffix + ".hextex"
			var image = Image.new()

			if not check(
				(
					image.load_webp_from_buffer(FileAccess.get_file_as_bytes(path)) == OK
					and image.get_size() == Vector2i(1024, 1536)
				),
				"Missing or low-resolution card print: " + card.id + suffix
			):
				return false

	return check(hashes.size() == 26, "Every card must have its own original illustration")

func check_decks() -> bool:
	MenuManager.set_menu(true, MenuTabs.Tab.HEX)
	await get_tree().process_frame
	var builder = MenuManager.menu_ui.content_uis.Hex

	if not check(
		HexManager.session.catalog.cards.size() == 160 and builder.definitions.size() == 186,
		"Native playable catalog must stay separate from the 26 previews"
	):
		return false

	builder._new()
	var before = builder.draft.duplicate()
	var saved = HexManager.save_decks()

	builder._change("FD-001", 1)

	if not check(
		before == builder.draft and saved == HexManager.save_decks(),
		"Clicking a preview must not change or save a battle deck"
	):
		return false

	var invalid = HexManager.active_deck.duplicate()

	invalid[0] = "FD-024"

	if not check(
		not HexManager.deck_errors(invalid).is_empty(),
		"Native deck validation must reject preview spells and Planes"
	):
		return false

	for index in range(builder.set_filter.item_count):
		if builder.set_filter.get_item_metadata(index) == "foundations":
			builder.set_filter.select(index)

	builder._collection()

	if not check(
		builder.grid.get_child_count() == 12 and builder.grid.get_child(0).get_child(1).disabled,
		"Foundations must be browsable with disabled add controls"
	):
		return false

	builder._hover("FD-001")

	if not check(
		builder.preview.visible and builder.preview.texture != null,
		"Preview cards must support full-size hover art"
	):
		return false

	MenuManager.hide_menu(true)

	return true

func check_shop() -> bool:
	var before = ShopManager.save_shop()

	if not check(
		(
			not ShopManager.buy_single("FD-001").ok
			and not ShopManager.buy_booster("foundations").ok
			and before == ShopManager.save_shop()
		),
		"Preview cards must not enter shop stock or booster pools"
	):
		return false

	ShopManager.open_shop()
	var ui = ShopManager.shop_ui

	ui.tabs.current_tab = 3
	ui.print_filter.select(1)
	ui._refresh()

	if not check(
		ui._entries().size() == 26 and ui._entries().all(func(id): return id.ends_with("-FA")),
		"Shop preview gallery must offer every full-art print"
	):
		return false

	var column = ui.grid.get_child(0).get_child(0)

	if not check(
		not column.get_children().any(func(child): return child is Button),
		"Preview gallery must have no take or purchase controls"
	):
		return false

	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://foundations-gallery.png")

	return true
