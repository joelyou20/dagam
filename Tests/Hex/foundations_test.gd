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
	cards = (
		JSON
		. parse_string(FileAccess.get_file_as_string("res://Resources/Hex/Data/foundations.json"))
		. cards
	)

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
	print("Foundations playable metadata, artwork and catalog checks passed: ", checks)
	get_tree().quit(0)

func check_metadata() -> bool:
	if not check(
		cards.size() == 26 and not HexManager.initialized,
		"Preview catalog must contain 26 cards without starting the battle engine"
	):
		return false

	var retired := 0

	for card in cards:
		if not check(
			not card.has("cost") and not card.has("terrain_types"),
			"Foundations must have no costs or terrain requirements"
		):
			return false

		if card.get("retired", false):
			retired += 1

			if not check(card.rules.is_empty(), "Only inert Planes are retired"):
				return false

	if not check(retired == 21, "Retire the six basic and fifteen dual Planes"):
		return false

	return check(
		cards[24].generated_only and cards[23].card_type == "Spell",
		"Vent remains generated and Erupt remains a Spell"
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
		HexManager.session.catalog.cards.size() == 186 and builder.definitions.size() == 186,
		"All Foundations cards must appear in the playable catalog"
	):
		return false

	builder._new()

	for i in range(3):
		builder._change("FD-001", 1)

	if not check(builder.draft.count("FD-001") == 0, "Inert Planes must not enter decks"):
		return false

	var before = builder.draft.duplicate()

	builder._change("FD-025", 1)

	if not check(builder.draft == before, "Generated Vent must not enter a deck"):
		return false

	builder._hover("FD-001")

	if not check(
		builder.preview.visible and builder.preview.texture != null, "Plane hover art must load"
	):
		return false

	MenuManager.hide_menu(true)

	return true

func check_shop() -> bool:
	if not check(
		(
			ShopManager.buy_single("FD-022").ok
			and not ShopManager.buy_single("FD-001").ok
			and not ShopManager.buy_single("FD-025").ok
		),
		"Shop must offer effect Planes and exclude inert Planes and generated Vent"
	):
		return false

	ShopManager.open_shop()
	var ui = ShopManager.shop_ui

	ui.tabs.current_tab = 3
	ui.print_filter.select(1)
	ui._refresh()

	if not check(
		ui._entries().size() == 26 and ui._entries().all(func(id): return id.ends_with("-FA")),
		"Foundations gallery must retain all full-art previews including generated terrain"
	):
		return false

	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://foundations-gallery.png")

	return true
