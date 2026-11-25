extends Node
var checks := 0
var world

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
	world = load("res://Scenes/TerrainTest.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await get_tree().create_timer(0.3).timeout
	MenuManager.set_menu(true, MenuTabs.Tab.HEX)
	await get_tree().process_frame
	var builder = MenuManager.menu_ui.content_uis.Hex
	var active: Array = HexManager.active_deck.duplicate()

	if not check(
		builder.archetype_selector.item_count == 16,
		"All pair and mono-Mage templates must be available"
	):
		return

	for i in range(builder.archetype_selector.item_count):
		if builder.archetype_selector.get_item_metadata(i).id == "mage_conclave":
			builder.archetype_selector.select(i)

	builder._from_archetype()

	if not check(
		builder.draft.size() == 30 and HexManager.deck_errors(builder.draft).is_empty(),
		"Mage template must be a legal complete deck"
	):
		return

	if not check(
		HexManager.active_deck == active,
		"Starting a template must not silently replace the active deck"
	):
		return

	if not check(
		builder.title.text == "Mage Conclave" and builder.deck_id.is_empty(),
		"Template must start a new named draft"
	):
		return

	var image = preload("res://Scripts/Hex/HexCardUI.gd").art("SA-044").get_image()
	var grey: Color = image.get_pixel(
		int(image.get_width() * 968 / 1024.0), int(image.get_height() * 396 / 1536.0)
	)
	var blue: Color = image.get_pixel(
		int(image.get_width() * 968 / 1024.0), int(image.get_height() * 290 / 1536.0)
	)

	if not check(
		absf(grey.r - grey.b) < 0.1 and grey.r > 0.3 and grey.r < 0.7,
		"Generic cost must render as grey, distinct from Light"
	):
		return

	if not check(blue.b > blue.r + 0.2, "Professor must show its Water requirement"):
		return

	builder._hover("SA-044")

	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_tree().root.get_texture().get_image().save_png("user://archetype-deck-builder.png")

	var complete: Array = builder.draft.duplicate()

	builder.draft = builder.draft.filter(
		func(id): return builder.definitions[id].card_type != "Plane"
	)
	builder._refresh()

	if not check(
		"Missing Power" in builder.metrics.text,
		"Existing decks must warn when Plane sources do not cover their costs"
	):
		return

	builder.draft = complete
	builder._refresh()

	builder._use()

	if not check(
		HexManager.active_deck == builder.draft,
		"Template must save and select through the normal battle-deck flow"
	):
		return

	MenuManager.hide_menu(true)
	MenuManager.menu_ui.queue_free()
	world.queue_free()
	await get_tree().create_timer(0.3).timeout
	print("Archetype deck-builder and mixed badge checks passed: ", checks)
	get_tree().quit()
