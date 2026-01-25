extends Node
class_name CardBattleSystem

# CardBattleSystem - Handles card-based battle mechanics

# Battle State
enum BattleState {
	SETUP,
	PLAYER_TURN,
	ENDED
}

var current_state: BattleState = BattleState.SETUP
var turn_number: int = 0

# Elemental Resources (Water, Fire, Earth, Air)
var player_water: int = 0
var player_fire: int = 0
var player_earth: int = 0
var player_air: int = 0

# Player Life
var player_life: int = 100  # Starting life
var player_max_life: int = 100

# Battle Data
var battle_data: BattleData = null

# Signals
signal water_changed(amount: int)
signal fire_changed(amount: int)
signal earth_changed(amount: int)
signal air_changed(amount: int)
signal life_changed(current: int, max: int)
signal turn_changed(turn_number: int)
signal battle_state_changed(new_state: BattleState)
signal hand_changed()
signal deck_changed()
signal discard_changed()

func _ready():
	pass

#region Battle Initialization

func _ensure_active_deck():
	# Ensure there's an active deck before battle starts
	# If no deck is set, try to create one from the collection
	if DeckManager.get_deck_size() == 0:
		var collection = DeckManager.get_all_collection_cards()
		if collection.size() > 0:
			# Build deck from collection
			var deck_cards: Array[CardResource] = []
			var cards_to_add = min(DeckManager.MAX_DECK_SIZE, collection.size())
			
			# If we have enough cards, use them all
			if collection.size() >= DeckManager.MIN_DECK_SIZE:
				for i in range(cards_to_add):
					deck_cards.append(collection[i])
			else:
				# Not enough cards in collection - duplicate cards to reach minimum
				var needed = DeckManager.MIN_DECK_SIZE
				var card_index = 0
				for i in range(needed):
					if card_index >= collection.size():
						card_index = 0  # Loop back if we run out
					var card = collection[card_index]
					var duplicated = CardManager.duplicate_card(card)
					deck_cards.append(duplicated)
					card_index += 1
			
			DeckManager.set_active_deck(deck_cards)
			print("Created default deck with %d cards from collection" % deck_cards.size())
		else:
			# No cards in collection - create a starter deck
			_create_starter_deck()

func _create_starter_deck():
	# Create a starter deck from the test card resource
	# Load the test card and fill deck with copies
	var test_card_path = "res://Resources/Cards/test_card.tres"
	
	if not ResourceLoader.exists(test_card_path):
		push_error("Test card not found at: " + test_card_path)
		push_error("Cannot create starter deck. Please ensure the test card exists or add cards to your collection.")
		return
	
	var base_card = load(test_card_path) as CardResource
	if not base_card:
		push_error("Failed to load test card from: " + test_card_path)
		return
	
	var starter_deck: Array[CardResource] = []
	var deck_size = DeckManager.MAX_DECK_SIZE  # Fill to max deck size
	
	# Create copies of the test card to fill the deck
	for i in range(deck_size):
		var card_copy = CardManager.duplicate_card(base_card)
		# Ensure each copy has a unique ID
		card_copy.id = base_card.id + "_" + str(i)
		# Ensure scene_path is set
		if card_copy.scene_path.is_empty():
			card_copy.scene_path = "res://Scenes/Cards/TestAttackCard.tscn"
		starter_deck.append(card_copy)
	
	# Add cards to collection
	for card in starter_deck:
		DeckManager.add_card_to_collection(card)
	
	# Set as active deck
	DeckManager.set_active_deck(starter_deck)
	print("Created starter deck with %d copies of test_card" % starter_deck.size())

func initialize_battle(battle_data_param: BattleData):
	# Initialize a card battle
	self.battle_data = battle_data_param
	current_state = BattleState.SETUP
	turn_number = 0
	
	
	# Initialize elemental resources (start with 1 of each)
	player_water = 0
	player_fire = 0
	player_earth = 0
	player_air = 0
	
	# Initialize player life
	if PlayerManager.player:
		player_life = PlayerManager.player.current_hp
		player_max_life = PlayerManager.player.max_hp
	else:
		player_life = 100
		player_max_life = 100
	
	# Initialize deck and hand
	_ensure_active_deck()
	
	# Check if we have a valid deck before initializing
	if DeckManager.get_deck_size() == 0:
		push_error("Cannot start battle: No valid deck available!")
		push_error("Please add cards to your collection or set an active deck before starting a battle.")
		current_state = BattleState.ENDED
		battle_state_changed.emit(current_state)
		return
	
	DeckManager.initialize_battle_deck()
	
	# Double-check that deck initialization succeeded
	if DeckManager.get_deck_remaining() == 0 and DeckManager.get_hand_size() == 0:
		push_error("Failed to initialize deck for battle!")
		current_state = BattleState.ENDED
		battle_state_changed.emit(current_state)
		return
	
	# Connect to DeckManager signals
	if not DeckManager.hand_changed.is_connected(_on_hand_changed):
		DeckManager.hand_changed.connect(_on_hand_changed)
	
	# Emit initial signals
	_emit_resource_signals()
	life_changed.emit(player_life, player_max_life)
	turn_changed.emit(turn_number)
	
	# Start first turn
	start_player_turn()

func start_player_turn():
	current_state = BattleState.PLAYER_TURN
	turn_number += 1
	
	# Gain 1 of each elemental resource at start of turn
	player_water += 1
	player_fire += 1
	player_earth += 1
	player_air += 1
	
	_emit_resource_signals()
	turn_changed.emit(turn_number)
	battle_state_changed.emit(current_state)
	
	# Draw a card at start of turn
	DeckManager.draw_card()
	
	print("Player Turn " + str(turn_number))

func end_turn():
	# Player ends their turn
	if current_state != BattleState.PLAYER_TURN:
		return
	
	# Process end-of-turn effects
	_process_end_of_turn_effects()
	
	# Check for battle end
	if _check_battle_end():
		return
	
	start_player_turn()

#endregion

#region Card Playing

func play_card(card_index: int) -> bool:
	# Play a card from hand
	if current_state != BattleState.PLAYER_TURN:
		push_warning("Not player's turn!")
		return false
	
	var hand = DeckManager.get_hand()
	if card_index < 0 or card_index >= hand.size():
		return false
	
	var card = hand[card_index]
	if not card:
		return false
	
	# Check if player can afford the card
	if not _can_afford_card(card):
		push_warning("Cannot afford to play " + card.name)
		return false

	# Pay costs
	player_water -= card.water_cost
	player_fire -= card.fire_cost
	player_earth -= card.earth_cost
	player_air -= card.air_cost
	_emit_resource_signals()
	
	# Play the card (removes from hand, adds to discard)
	var played_card = DeckManager.play_card(card_index)
	if not played_card:
		return false
	
	# Execute card effect
	_execute_card_effect(played_card)
	
	return true

func discard_card(card_index: int) -> bool:
	# Discard a card from hand without playing it
	if current_state != BattleState.PLAYER_TURN:
		return false
	
	var discarded = DeckManager.discard_card(card_index)
	return discarded != null

func _can_afford_card(card: CardResource) -> bool:
	# Check if player has enough elemental resources
	return player_water >= card.water_cost and \
		   player_fire >= card.fire_cost and \
		   player_earth >= card.earth_cost and \
		   player_air >= card.air_cost

func _execute_card_effect(card: CardResource):
	# Execute the effect of a played card
	# For now, just print - effects can be expanded later
	print("Played card: " + card.name)
	
	# Run custom effect script if present
	if card.effect_script:
		var effect = card.effect_script.new()
		if effect.has_method("run"):
			effect.run(card, null)

func draw_card() -> CardResource:
	# Draw a card (wrapper for DeckManager)
	return DeckManager.draw_card()

func _on_hand_changed():
	# Called when hand changes in DeckManager
	hand_changed.emit()

#endregion

#region Resource Management

func _emit_resource_signals():
	# Emit signals for all resources
	water_changed.emit(player_water)
	fire_changed.emit(player_fire)
	earth_changed.emit(player_earth)
	air_changed.emit(player_air)

func get_water() -> int:
	return player_water

func get_fire() -> int:
	return player_fire

func get_earth() -> int:
	return player_earth

func get_air() -> int:
	return player_air

#endregion

#region Life Management
	
func set_life(amount: int):
	player_life = clamp(amount, 0, player_max_life)
	life_changed.emit(player_life, player_max_life)

func add_life(amount: int):
	set_life(player_life + amount)

func get_life() -> int:
	return player_life
	

func _process_end_of_turn_effects():
	# Process effects that happen at end of turn
	# Could include status effects, regeneration, etc.
	pass
	
func get_max_life() -> int:
	return player_max_life

#endregion

#region Battle End

func _check_battle_end() -> bool:
	# Check if battle should end
	if player_life <= 0:
		print("Player defeated! Battle lost.")
		current_state = BattleState.ENDED
		battle_state_changed.emit(current_state)
		return true
	
	return false

func end_battle(victory: bool):
	# End the battle
	current_state = BattleState.ENDED
	battle_state_changed.emit(current_state)
	
	if victory:
		print("Battle won!")
		# Grant rewards, experience to cards, etc.
		_grant_battle_rewards()
	else:
		print("Battle lost!")

func _grant_battle_rewards():
	# Grant rewards after winning a battle
	if battle_data:
		# Rewards can be granted here
		pass

#endregion

#region Getters

func get_current_state() -> BattleState:
	return current_state

func get_turn_number() -> int:
	return turn_number

#endregion
