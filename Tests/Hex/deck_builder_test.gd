extends Node
var checks := 0

func _ready():
	call_deferred("run")

func check(ok: bool, message: String) -> bool:
	if not ok:
		push_error(message)
		get_tree().quit(1)

		return false

	checks += 1

	return true

func frames():
	await get_tree().process_frame
	await get_tree().process_frame

func run():
	var world = load("res://Scenes/Root.tscn").instantiate()

	get_tree().root.add_child(world)
	get_tree().current_scene = world

	for i in range(12):
		await get_tree().process_frame

	MenuManager.set_menu(true, MenuTabs.Tab.OPTIONS)
	MenuManager.menu_ui.get_node("VBoxContainer/MenuTopNav/HBoxContainer/HexButton").pressed.emit()
	await frames()
	var builder = MenuManager.menu_ui.content_uis.Hex
	var original_profile = HexManager.save_decks()

	if not check(
		builder.visible and not HexManager.is_battle_open(),
		"Hex menu opened a battle instead of the editor"
	):
		return

	if not check(HexManager.session.state.is_empty(), "Deck editor created a match"):
		return

	if not check(
		(
			builder.definitions.size()
			== HexManager.session.catalog.cards.size() + HexPreviewCatalog.cards().size()
		),
		"All playable cards and Foundations previews must be visible"
	):
		return

	if not check(
		HexManager.active_deck == HexManager.session.catalog.starter,
		"Starter must be the initial battle deck"
	):
		return

	builder.search.text = "Zap"
	builder._collection()

	if not check(builder.grid.get_child_count() == 1, "Card search did not filter catalogue"):
		return

	builder.search.text = "Sprint"
	builder._collection()

	if not check(builder.grid.get_child_count() > 0, "Keyword ability search failed"):
		return

	builder.search.text = ""
	builder._new()
	builder._change("LT-001", 1)
	builder._change("LT-001", 1)
	builder._change("LT-001", 1)

	if not check(builder.draft.count("LT-001") == 2, "UI exceeded two-copy limit"):
		return

	builder._new()
	builder._change("WE-045", 1)
	builder._change("WE-045", 1)

	if not check(builder.draft.count("WE-045") == 1, "Single-copy card limit was ignored"):
		return

	var invalid = []

	for i in range(20):
		invalid.append("LT-001")

	if not check(not HexManager.deck_errors(invalid).is_empty(), "Engine accepted excess copies"):
		return

	if not check(
		not HexManager.deck_errors(["unknown"]).is_empty(), "Engine accepted unknown card"
	):
		return

	var cards = []

	for card in HexManager.session.catalog.cards:
		if card.card_type == "Spell" and cards.size() < 30:
			cards.append(card.id)
			cards.append(card.id)

	if not check(HexManager.deck_errors(cards).is_empty(), "All-spell deck was rejected"):
		return

	var id = HexManager.save_deck("", "All spells", cards)

	if not check(
		not id.is_empty() and HexManager.use_deck(id), "Valid deck could not be saved/selected"
	):
		return

	builder.draft = cards.duplicate()
	builder._change("LT-001", 1)

	if not check(builder.draft.size() == 30, "UI exceeded 30-card deck size"):
		return

	builder._duplicate()

	if not check(
		builder.deck_id.is_empty() and builder.draft == cards,
		"Duplicate did not copy editable cards"
	):
		return

	var profile = HexManager.save_decks()
	var disk = load("res://Scripts/Managers/HexManager.gd").new()

	disk.initialize()

	if not check(
		disk.active_deck == cards and disk.decks.any(func(d): return d.id == id),
		"Decks did not survive disk reload"
	):
		return

	disk.free()
	HexManager.request({"op": "new", "seed": 42})
	var saved = HexManager.save_hex()
	var actual = saved.game.players[0].deck.map(func(c): return c.id)

	actual.sort()
	var expected = cards.duplicate()

	expected.sort()

	if not check(actual == expected, "New battle did not use selected deck"):
		return

	HexManager.use_deck("starter")

	if not check(
		HexManager.save_hex().game.players[0].deck == saved.game.players[0].deck,
		"Deck selection changed an ongoing match"
	):
		return

	if not check(
		HexManager.start_encounter(
			{
				"deck_id": "thornbound",
				"enemy_id": "",
				"scene_path": SceneManager.current_scene.scene_file_path
			}
		),
		"Encounter did not start"
	):
		return

	var enemy_game = HexManager.save_hex().game

	actual = enemy_game.players[0].deck.map(func(c): return c.id)
	actual.sort()
	expected = HexManager.session.catalog.starter.duplicate()
	expected.sort()

	if not check(actual == expected, "Encounter did not use current deck selection"):
		return

	HexManager.restore_practice()

	if not check(
		HexManager.save_hex().game.players[0].deck == saved.game.players[0].deck,
		"Encounter did not restore original practice deck"
	):
		return

	if not check(
		HexManager.load_decks(profile) and HexManager.active_deck == cards,
		"Shared deck profile restore failed"
	):
		return

	var broken = profile.duplicate(true)

	broken.active = invalid

	if not check(
		not HexManager.load_decks(broken) and HexManager.active_deck == cards,
		"Invalid profile overwrote active deck"
	):
		return

	GameStateManager.save_game_to_file("user://deck-builder-game.dat")
	var file = FileAccess.open("user://deck-builder-game.dat", FileAccess.READ)
	var data = file.get_var()

	file.close()

	if not check(data.hex_decks.active == cards, "RPG save omitted selected decks"):
		return

	HexManager.delete_deck(id)

	if not check(
		not HexManager.decks.any(func(d): return d.id == id), "Delete did not remove deck"
	):
		return

	if not check(HexManager.load_decks(original_profile), "Initial profile could not be restored"):
		return

	if DisplayServer.get_name() != "headless":
		builder._select(0)
		await frames()
		await get_tree().create_timer(0.7).timeout
		get_tree().root.get_texture().get_image().save_png("user://hex-deck-builder.png")

	var hotkey = InputEventAction.new()

	hotkey.action = "toggle_hex_menu"
	hotkey.pressed = true
	world._unhandled_input(hotkey)

	if not check(
		not MenuManager.menu_ui.visible, "H did not close the Hex page opened from the menu button"
	):
		return

	if not check(not InteractionHandler.is_blocked(), "Deck editor did not release world input"):
		return

	print("Deck builder and selected battle deck checks passed: ", checks)
	MenuManager.menu_ui.queue_free()
	world.queue_free()
	await get_tree().create_timer(0.4).timeout
	get_tree().quit()
