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
		builder.draft.size() == 20 and HexManager.deck_errors(builder.draft).is_empty(),
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

	if not check(
		not builder.definitions["SA-044"].has("cost"), "Card definitions must not contain costs"
	):
		return

	builder._hover("SA-044")

	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_tree().root.get_texture().get_image().save_png("user://archetype-deck-builder.png")

	if not check(not "Power" in builder.metrics.text, "Deck metrics must not require resources"):
		return

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
	print("Free-play archetype deck-builder checks passed: ", checks)
	get_tree().quit()
