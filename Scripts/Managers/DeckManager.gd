extends Node

# DeckManager - Manages player's card collection and decks

# Card Collection - all cards the player owns
var card_collection: Array[CardResource] = []

# Active Deck - the deck currently being used in battle
var active_deck: Array[CardResource] = []

# Deck Size Limits
const MAX_DECK_SIZE: int = 30
const MIN_DECK_SIZE: int = 20
const MAX_HAND_SIZE: int = 7
const MAX_COLLECTION_SIZE: int = 999  # Maximum cards in collection

# Current Hand - cards available to play
var current_hand: Array[CardResource] = []

# Deck - cards remaining to draw
var deck: Array[CardResource] = []

# Discard Pile - cards that have been played/discarded
var discard_pile: Array[CardResource] = []

signal card_added_to_collection(card: CardResource)
signal card_removed_from_collection(card: CardResource)
signal deck_changed()
signal hand_changed()

func _ready():
	# Initialize empty deck
	active_deck = []
	card_collection = []
	
	# Initialize deck from test card if collection is empty
	_initialize_default_deck()

func _initialize_default_deck():
	# Initialize player with a deck if they don't have one
	if card_collection.is_empty() and active_deck.is_empty():
		var test_card_path = "res://Resources/Cards/test_card.tres"
		
		if ResourceLoader.exists(test_card_path):
			var base_card = load(test_card_path) as CardResource
			if base_card:
				var deck_cards: Array[CardResource] = []
				
				# Fill deck to MAX_DECK_SIZE with copies of the test card
				for i in range(MAX_DECK_SIZE):
					var card_copy = CardManager.duplicate_card(base_card)
					# Ensure each copy has a unique ID
					card_copy.id = base_card.id + "_" + str(i)
					# Ensure scene_path is set (use default if not set in resource)
					if card_copy.scene_path.is_empty():
						card_copy.scene_path = "res://Scenes/Cards/TestAttackCard.tscn"
					deck_cards.append(card_copy)
				
				# Add cards to collection
				for card in deck_cards:
					card_collection.append(card)
				
				# Set as active deck
				active_deck = deck_cards.duplicate()
				deck_changed.emit()
				print("Initialized player deck with %d copies of test_card" % deck_cards.size())

#region Collection Management

func add_card_to_collection(card: CardResource, amount: int = 1):
	# Add card(s) to collection
	for i in range(amount):
		var new_card = CardManager.duplicate_card(card)
		card_collection.append(new_card)
	
	card_added_to_collection.emit(card)
	print("Added %d %s to collection" % [amount, card.name])

func remove_card_from_collection(card_id: String, amount: int = 1) -> bool:
	# Remove card(s) from collection by ID
	var removed = 0
	for i in range(card_collection.size() - 1, -1, -1):
		if card_collection[i].id == card_id and removed < amount:
			card_collection.remove_at(i)
			removed += 1
	
	if removed > 0:
		card_removed_from_collection.emit(card_collection.find(func(c): return c.id == card_id))
		return true
	return false

func get_card_from_collection(card_id: String) -> CardResource:
	# Get a card from collection by ID
	for card in card_collection:
		if card.id == card_id:
			return card
	return null

func get_collection_size() -> int:
	return card_collection.size()

func get_all_collection_cards() -> Array[CardResource]:
	# Get all cards from the collection
	return card_collection.duplicate()

func has_card(card_id: String) -> bool:
	return get_card_from_collection(card_id) != null

func get_cards_by_rarity(rarity: CardRarity.Rarity) -> Array[CardResource]:
	return card_collection.filter(func(card: CardResource): return card.rarity == rarity)

func get_cards_by_type(card_type: CardResource.CardType) -> Array[CardResource]:
	return card_collection.filter(func(card: CardResource): return card.card_type == card_type)

#endregion

#region Deck Management

func set_active_deck(cards: Array[CardResource]) -> bool:
	# Set the active deck (must be within size limits)
	if cards.size() < MIN_DECK_SIZE:
		push_error("Deck too small! Minimum size is %d" % MIN_DECK_SIZE)
		return false
	if cards.size() > MAX_DECK_SIZE:
		push_error("Deck too large! Maximum size is %d" % MAX_DECK_SIZE)
		return false
	
	active_deck = cards.duplicate()
	deck_changed.emit()
	print("Active deck set with %d cards" % active_deck.size())
	return true

func add_card_to_deck(card: CardResource) -> bool:
	# Add a card to the active deck
	if active_deck.size() >= MAX_DECK_SIZE:
		push_warning("Deck is full!")
		return false
	
	active_deck.append(card)
	deck_changed.emit()
	return true

func remove_card_from_deck(index: int) -> bool:
	# Remove a card from the active deck by index
	if index < 0 or index >= active_deck.size():
		return false
	
	active_deck.remove_at(index)
	deck_changed.emit()
	return true

func get_active_deck() -> Array[CardResource]:
	return active_deck.duplicate()

func get_deck_size() -> int:
	return active_deck.size()

func is_deck_valid() -> bool:
	return active_deck.size() >= MIN_DECK_SIZE and active_deck.size() <= MAX_DECK_SIZE

#endregion

#region Battle Deck Management

func initialize_battle_deck():
	# Shuffle and prepare deck for battle
	if active_deck.is_empty():
		push_error("Cannot initialize battle: No active deck set!")
		return
	
	deck = active_deck.duplicate()
	shuffle_deck()
	current_hand = []
	discard_pile = []
	
	# Draw initial hand
	draw_initial_hand()

func shuffle_deck():
	# Shuffle the deck using Fisher-Yates
	for i in range(deck.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = deck[i]
		deck[i] = deck[j]
		deck[j] = temp

func draw_initial_hand():
	# Draw cards up to MAX_HAND_SIZE
	var cards_to_draw = min(MAX_HAND_SIZE, deck.size())
	for i in range(cards_to_draw):
		draw_card()

func draw_card() -> CardResource:
	# Draw one card from deck
	if deck.is_empty():
		# Reshuffle discard pile if deck is empty
		if not discard_pile.is_empty():
			reshuffle_discard_pile()
		else:
			# No cards left to draw
			return null
	
	if current_hand.size() >= MAX_HAND_SIZE:
		push_warning("Hand is full! Cannot draw more cards.")
		return null
	
	var card = deck.pop_front()
	current_hand.append(card)
	hand_changed.emit()
	return card

func play_card(card_index: int) -> CardResource:
	# Play a card from hand (remove from hand, add to discard)
	if card_index < 0 or card_index >= current_hand.size():
		return null
	
	var card = current_hand[card_index]
	current_hand.remove_at(card_index)
	discard_pile.append(card)
	hand_changed.emit()
	return card

func discard_card(card_index: int) -> CardResource:
	# Discard a card from hand without playing it
	return play_card(card_index)  # Same behavior for now

func reshuffle_discard_pile():
	# Shuffle discard pile back into deck
	deck.append_array(discard_pile)
	discard_pile.clear()
	shuffle_deck()
	print("Reshuffled discard pile into deck")

func get_hand() -> Array[CardResource]:
	return current_hand.duplicate()

func get_hand_size() -> int:
	return current_hand.size()

func get_deck_remaining() -> int:
	return deck.size()

func get_discard_size() -> int:
	return discard_pile.size()

#endregion

#region Save/Load

func save_deck_manager() -> Dictionary:
	var collection_data := []
	for card in card_collection:
		var card_data = {
			"id": card.id,
			"resource_path": card.resource_path if card.resource_path else "",
			"name": card.name,
			"description": card.description,
			"rarity": card.rarity,
			"card_type": card.card_type,
			"mana_cost": card.mana_cost,
			"energy_cost": card.energy_cost,
			"creature_stats": card.creature_stats.duplicate(),
			"level": card.level,
			"experience": card.experience,
			"experience_to_next_level": card.experience_to_next_level,
			"captured_from_id": card.captured_from_id,
			"capture_date": card.capture_date,
			"abilities": card.abilities.duplicate()
		}
		collection_data.append(card_data)
	
	var deck_data := []
	for card in active_deck:
		# For deck, just save the card ID (must exist in collection)
		deck_data.append({
			"id": card.id
		})
	
	return {
		"collection": collection_data,
		"active_deck": deck_data
	}

func load_deck_manager(data: Dictionary):
	card_collection.clear()
	active_deck.clear()
	
	# Load collection
	var collection_data = data.get("collection", [])
	for card_data in collection_data:
		var card: CardResource
		
		# Try to load from resource path first
		if card_data.has("resource_path") and not card_data["resource_path"].is_empty():
			card = load(card_data["resource_path"]) as CardResource
			if card:
				# Update runtime data
				card.level = card_data.get("level", card.level)
				card.experience = card_data.get("experience", card.experience)
				card.experience_to_next_level = card_data.get("experience_to_next_level", card.experience_to_next_level)
				card.captured_from_id = card_data.get("captured_from_id", card.captured_from_id)
				card.capture_date = card_data.get("capture_date", card.capture_date)
		else:
			# Create card from serialized data (for dynamically created cards)
			card = CardResource.new()
			card.id = card_data.get("id", "")
			card.name = card_data.get("name", "")
			card.description = card_data.get("description", "")
			card.rarity = card_data.get("rarity", CardRarity.Rarity.COMMON)
			card.card_type = card_data.get("card_type", CardResource.CardType.CREATURE)
			card.mana_cost = card_data.get("mana_cost", 0)
			card.energy_cost = card_data.get("energy_cost", 0)
			card.creature_stats = card_data.get("creature_stats", {})
			card.level = card_data.get("level", 1)
			card.experience = card_data.get("experience", 0)
			card.experience_to_next_level = card_data.get("experience_to_next_level", 100)
			card.captured_from_id = card_data.get("captured_from_id", "")
			card.capture_date = card_data.get("capture_date", "")
			card.abilities = card_data.get("abilities", [])
		
		if card:
			card_collection.append(card)
	
	# Load active deck (must reference cards in collection)
	var deck_data = data.get("active_deck", [])
	for card_data in deck_data:
		var card_id = card_data.get("id", "")
		var card = get_card_from_collection(card_id)
		if card:
			active_deck.append(card)
		else:
			push_warning("Card not found in collection for deck: " + card_id)
	
	deck_changed.emit()

#endregion
