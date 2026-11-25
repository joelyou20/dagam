extends Node
## Owns Hex state like the other game managers; screens only present it.
signal match_restored
signal match_error(message: String)
signal decks_changed
const Session = preload("res://Scripts/Hex/HexSession.gd")
const DECK_SAVE := "user://dagam-hex-decks-v1.json"
var battle_ui: HexBattleUI
var session: RefCounted = Session.new()
var initialized: bool = false
var decks: Array = []
var active_deck: Array = []
var active_deck_name := "Starter deck"

func initialize() -> bool:
	if initialized:
		return true

	initialized = session.initialize()

	if initialized:
		_load_decks()

	if not initialized:
		match_error.emit(session.last_error)

	return initialized

func ensure_match() -> bool:
	if not initialize():
		return false

	if session.state.is_empty() and not session.load_match():
		session.request(
			{
				"op": "new",
				"seed": int(Time.get_unix_time_from_system()),
				"enemy": "thornbound",
				"deck": active_deck
			}
		)

	if is_encounter() and not BattleManager.hex_encounter_active:
		BattleManager.resume_hex_encounter()

	return not session.state.is_empty()

func is_encounter() -> bool:
	return initialized and session.state.get("encounter") != null

func encounter_metadata() -> Dictionary:
	return session.state.get("encounter", {}) if is_encounter() else {}

func start_encounter(metadata: Dictionary, seed: int = 0) -> bool:
	if not ensure_match() or is_encounter():
		return false

	var practice: Dictionary = session.request({"op": "save"})
	var result: Dictionary = session.request(
		{
			"op": "new",
			"seed": seed if seed else int(Time.get_unix_time_from_system()),
			"enemy": metadata.deck_id,
			"encounter": metadata,
			"practice": practice.get("game"),
			"deck": active_deck
		}
	)

	if result.is_empty():
		return false

	session.save_match()

	return true

func restore_practice() -> void:
	var saved: Dictionary = session.request({"op": "save"})
	var practice = saved.get("game", {}).get("context", {}).get("practice_game")
	var restored: Dictionary = {}

	if practice is Dictionary:
		restored = session.request({"op": "load", "game": practice})

	if restored.is_empty():
		session.request(
			{
				"op": "new",
				"enemy": "thornbound",
				"seed": int(Time.get_unix_time_from_system()),
				"deck": active_deck
			}
		)

	session.save_match()

func request(command: Dictionary) -> Dictionary:
	if not initialize():
		return {}

	if is_encounter() and command.get("op") == "new":
		return {"ok": false, "state": session.state}

	var request_data = command.duplicate()

	if request_data.get("op") == "new":
		request_data["deck"] = active_deck.duplicate()

	return session.request(request_data)

func save_match() -> bool:
	return initialized and not session.state.is_empty() and session.save_match()

func save_hex() -> Dictionary:
	if not initialized or session.state.is_empty():
		return {}

	return session.request({"op": "save"})

func load_hex(data: Dictionary) -> bool:
	if data.is_empty():
		if is_encounter():
			restore_practice()
			BattleManager.on_hex_state_loaded()
			match_restored.emit()

		return true

	if data.get("version") != 1 or not data.get("game") is Dictionary:
		match_error.emit("Unsupported Hex match in game save.")

		return false

	if not initialize():
		return false

	var result: Dictionary = session.request({"op": "load", "game": data.game})

	if result.is_empty():
		return false

	BattleManager.on_hex_state_loaded()
	session.save_match()
	match_restored.emit()

	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_match()

func is_battle_open() -> bool:
	return is_instance_valid(battle_ui) and battle_ui.visible

func open_battle() -> void:
	ShopManager.close_shop()

	if not ensure_match():
		return

	MenuManager.hide_menu(true)

	if not is_instance_valid(battle_ui):
		battle_ui = load("res://Scenes/Hex/HexBattleUI.tscn").instantiate()
		get_tree().root.add_child(battle_ui)

	battle_ui.show_ui()

func close_battle(force: bool = false) -> void:
	if not is_battle_open():
		return

	if force:
		battle_ui.hide_ui()
	else:
		battle_ui.on_cancel()

func toggle_battle() -> void:
	if is_battle_open():
		close_battle()
	else:
		open_battle()

func deck_errors(cards: Array, draft: bool = false) -> Array:
	if not initialize():
		return ["Card catalogue unavailable."]

	return session.request({"op": "deckcheck", "cards": cards, "draft": draft}).get("errors", [])

func save_deck(id: String, title: String, cards: Array) -> String:
	if not initialize():
		return ""
	# Incomplete decks may be saved as drafts; card limits still apply.

	if not deck_errors(cards, true).is_empty():
		return ""

	var previous = decks.duplicate(true)

	if id.is_empty():
		id = "deck-" + str(Time.get_unix_time_from_system()) + "-" + str(Time.get_ticks_usec())

	var item = {
		"id": id,
		"name":
		title.strip_edges().left(48) if not title.strip_edges().is_empty() else "Untitled deck",
		"cards": cards.duplicate()
	}
	var index = decks.find_custom(func(d): return d.id == id)

	if index < 0:
		decks.append(item)
	else:
		decks[index] = item

	if not _persist_decks():
		decks = previous

		return ""

	decks_changed.emit()

	return id

func use_deck(id: String) -> bool:
	var index = decks.find_custom(func(d): return d.id == id)

	if index < 0 or not deck_errors(decks[index].cards).is_empty():
		return false

	var old_cards = active_deck.duplicate()
	var old_name = active_deck_name

	active_deck = decks[index].cards.duplicate()
	active_deck_name = decks[index].name

	if not _persist_decks():
		active_deck = old_cards
		active_deck_name = old_name

		return false

	decks_changed.emit()

	return true

func delete_deck(id: String) -> bool:
	var previous = decks.duplicate(true)

	decks = decks.filter(func(d): return d.id != id)

	if not _persist_decks():
		decks = previous

		return false

	decks_changed.emit()

	return true

func save_decks() -> Dictionary:
	if not initialize():
		return {}

	return {
		"version": 1,
		"decks": decks.duplicate(true),
		"active": active_deck.duplicate(),
		"name": active_deck_name
	}

func load_decks(data: Dictionary) -> bool:
	if data.is_empty():
		return true

	if (
		not initialize()
		or data.get("version") != 1
		or not data.get("decks") is Array
		or not data.get("active") is Array
	):
		return false

	if not deck_errors(data.active).is_empty():
		return false

	var restored = []
	var ids = {}

	for item in data.decks:
		if (
			not item is Dictionary
			or not item.get("cards") is Array
			or not item.get("id") is String
			or not item.get("name") is String
			or ids.has(item.id)
		):
			return false

		if not deck_errors(item.cards, true).is_empty():
			return false

		ids[item.id] = true
		restored.append(item.duplicate(true))

	decks = restored
	active_deck = data.active.duplicate()
	active_deck_name = str(data.get("name", "Custom deck")).left(48)
	_persist_decks()
	decks_changed.emit()

	return true

func _load_decks():
	active_deck = session.catalog.starter.duplicate()
	decks = [{"id": "starter", "name": "Starter deck", "cards": active_deck.duplicate()}]

	if not FileAccess.file_exists(DECK_SAVE):
		return

	var data = JSON.parse_string(FileAccess.get_file_as_string(DECK_SAVE))

	if data is Dictionary:
		load_decks(data)

func _persist_decks() -> bool:
	var file = FileAccess.open(DECK_SAVE + ".tmp", FileAccess.WRITE)

	if file == null:
		match_error.emit("Unable to save decks.")

		return false

	file.store_string(
		JSON.stringify(
			{"version": 1, "decks": decks, "active": active_deck, "name": active_deck_name}
		)
	)
	file.close()

	if DirAccess.rename_absolute(DECK_SAVE + ".tmp", DECK_SAVE) != OK:
		match_error.emit("Unable to save decks.")

		return false

	return true
