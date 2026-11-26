extends Node
## Free testing stock. Transactions persist collection changes before reporting success.
signal changed
const SAVE := "user://dagam-shop-v1.json"
const SETS := {
	"first-light": "First Light",
	"shattered-arcana": "Shattered Arcana",
	"war-on-elderberry": "War on Elderberry"
}
var collection: Dictionary = {}
var definitions: Dictionary = {}
var preview_definitions: Dictionary = {}
var shop_ui: UIBase
var save_path := SAVE
var _random := RandomNumberGenerator.new()
var _illustrations: Array = []

func _ready() -> void:
	_random.randomize()

	for card in JSON.parse_string(
		FileAccess.get_file_as_string("res://Resources/Hex/Data/cards.json")
	):
		definitions[card.id] = card

	for card in HexPreviewCatalog.cards():
		preview_definitions[card.id] = card

	_illustrations = JSON.parse_string(
		FileAccess.get_file_as_string("res://Resources/Hex/Data/illustration-rares.json")
	)

	if FileAccess.file_exists(save_path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))

		if data is Dictionary and data.get("version") == 1:
			load_shop(data, false)

	SceneManager.scene_loaded.connect(close_shop)

func base_id(id: String) -> String:
	return id.trim_suffix("-FA").trim_suffix("-IR")

func card_data(id: String) -> Dictionary:
	var source: Dictionary = definitions.get(base_id(id), preview_definitions.get(base_id(id), {}))

	if source.is_empty():
		return {}

	var card: Dictionary = source.duplicate(true)

	card.id = id

	return card

func valid_print(id: String) -> bool:
	return (
		definitions.has(base_id(id))
		and not definitions[base_id(id)].get("generated_only", false)
		and not definitions[base_id(id)].get("retired", false)
		and FileAccess.file_exists("res://Assets/Hex/cards/" + id + ".hextex")
	)

func quantity(id: String) -> int:
	return int(collection.get(id, 0))

func is_open() -> bool:
	return is_instance_valid(shop_ui) and shop_ui.visible

func open_shop() -> bool:
	if HexManager.is_battle_open() or HexManager.is_encounter() or UIManager.has_open_ui():
		return false

	if not is_instance_valid(shop_ui):
		shop_ui = load("res://Scenes/UI/ShopUI.tscn").instantiate()
		get_tree().root.add_child(shop_ui)

	shop_ui.show_ui()

	return true

func close_shop() -> void:
	if is_open():
		shop_ui.hide_ui()

func buy_single(id: String) -> Dictionary:
	if not valid_print(id):
		return _error("This card is unavailable.")

	return _purchase([id])

func buy_booster(set_id: String) -> Dictionary:
	if not SETS.has(set_id):
		return _error("This set is unavailable.")

	var cards: Array = []

	for rarity in ["Common", "Common", "Common", "Uncommon", _rare_rarity(set_id)]:
		var pool = definitions.values().filter(
			func(c): return c.set == set_id and c.rarity == rarity and not c.id in cards
		)

		if pool.is_empty():
			return _error("This booster is unavailable.")

		cards.append(pool[_random.randi_range(0, pool.size() - 1)].id)

	# Cosmetic upgrades never change the underlying card's rules or deck access.

	for index in range(cards.size()):
		var id: String = cards[index]
		var roll = _random.randf()

		if id in _illustrations and roll < 0.04 and valid_print(id + "-IR"):
			cards[index] = id + "-IR"
		elif roll < 0.20 and valid_print(id + "-FA"):
			cards[index] = id + "-FA"

	return _purchase(cards)

func _rare_rarity(set_id: String) -> String:
	var roll = _random.randi_range(1, 100)
	var rarity = (
		"Mythic" if roll == 100 else "Legendary" if roll >= 96 else "Epic" if roll >= 81 else "Rare"
	)

	if definitions.values().any(func(c): return c.set == set_id and c.rarity == rarity):
		return rarity

	return "Rare"

func _purchase(cards: Array) -> Dictionary:
	if HexManager.is_battle_open() or HexManager.is_encounter():
		return _error("Finish your battle before trading.")

	var updated = collection.duplicate()

	for id in cards:
		updated[id] = int(updated.get(id, 0)) + 1

	if not _commit(updated):
		return _error("Unable to save these cards. Please try again.")

	return {"ok": true, "cards": cards}

func return_card(id: String) -> Dictionary:
	if HexManager.is_battle_open() or HexManager.is_encounter():
		return _error("Finish your battle before trading.")

	if not valid_print(id) or quantity(id) <= 0:
		return _error("You do not own this card.")

	var updated = collection.duplicate()

	updated[id] -= 1

	if updated[id] == 0:
		updated.erase(id)

	if not _commit(updated):
		return _error("Unable to save this change. Your card was kept.")

	return {"ok": true}

func save_shop() -> Dictionary:
	return {"version": 1, "collection": collection.duplicate()}

func load_shop(data: Dictionary, persist := true) -> bool:
	if data.get("version") != 1 or not data.get("collection") is Dictionary:
		return false

	var restored: Dictionary = {}

	for id in data.collection:
		var count = data.collection[id]

		if (
			not id is String
			or not valid_print(id)
			or not (count is int or count is float)
			or int(count) <= 0
			or float(count) != float(int(count))
		):
			return false

		restored[id] = int(count)

	if persist:
		return _commit(restored)

	collection = restored
	changed.emit()

	return true

func _commit(new_collection: Dictionary) -> bool:
	var previous = save_shop()

	collection = new_collection

	if not _persist():
		collection = previous.collection

		return false

	changed.emit()

	return true

func _persist() -> bool:
	var file = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)

	if file == null:
		return false

	file.store_string(JSON.stringify(save_shop()))
	file.flush()
	var error = file.get_error()

	file.close()

	if error != OK:
		return false

	return (
		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(save_path + ".tmp"),
			ProjectSettings.globalize_path(save_path)
		)
		== OK
	)

func _error(message: String) -> Dictionary:
	return {"ok": false, "message": message}
