extends UIBase
class_name BattleUI

# BattleUI - UI for card-based battle system

# Card Battle System reference
var card_battle_system: CardBattleSystem = null

# UI Elements - TextLabels for displaying battle info
@onready var deck_label: Label = $Panel/DeckTextLabel if has_node("Panel/DeckTextLabel") else null
@onready var discard_label: Label = $Panel/DiscardTextLabel if has_node("Panel/DiscardTextLabel") else null
@onready var turn_label: Label = $Panel/TurnTextLabel if has_node("Panel/TurnTextLabel") else null
@onready var life_label: Label = $Panel/LifeTextLabel if has_node("Panel/LifeTextLabel") else null
@onready var water_label: Label = $Panel/WaterManaTextLabel if has_node("Panel/WaterManaTextLabel") else null
@onready var fire_label: Label = $Panel/FireManaTextLabel if has_node("Panel/FireManaTextLabel") else null
@onready var earth_label: Label = $Panel/EarthManaTextLabel if has_node("Panel/EarthManaTextLabel") else null
@onready var air_label: Label = $Panel/AirManaTextLabel if has_node("Panel/AirManaTextLabel") else null

# Player Hand Container
@onready var player_hand_container: HBoxContainer = $Panel/PlayerHandContainer if has_node("Panel/PlayerHandContainer") else null

# Optional: Keep some UI elements if they exist in the scene
@onready var flee_button: Button = $Panel/GridContainer/FleeButton if has_node("Panel/GridContainer/FleeButton") else null

# Card scene fallback
const DEFAULT_CARD_SCENE = "res://Scenes/Cards/TestAttackCard.tscn"

func _ready():
	# Find CardBattleSystem in the scene tree
	# BattleController creates it as a child of the scene root
	var scene_root = get_tree().current_scene
	if scene_root:
		card_battle_system = scene_root.get_node_or_null("CardBattleSystem") as CardBattleSystem
		if not card_battle_system:
			# Try to find BattleController first, then get CardBattleSystem from it
			var battle_controller = scene_root if scene_root.name == "BattleController" else scene_root.get_node_or_null("BattleController")
			if battle_controller:
				card_battle_system = battle_controller.get_node_or_null("CardBattleSystem") as CardBattleSystem
	
	if not card_battle_system:
		# Try to find it anywhere in the scene tree
		card_battle_system = get_tree().get_first_node_in_group("CardBattleSystem") as CardBattleSystem
		if not card_battle_system:
			# Search recursively
			card_battle_system = _find_card_battle_system(get_tree().root)
	
	if not card_battle_system:
		push_warning("CardBattleSystem not found! BattleUI will not function properly.")
		return
	
	if not player_hand_container:
		push_warning("PlayerHandContainer not found at path: Panel/PlayerHandContainer")
		# Try to find it with a different path
		player_hand_container = get_node_or_null("PlayerHandContainer") as HBoxContainer
		if not player_hand_container:
			player_hand_container = get_node_or_null("%PlayerHandContainer") as HBoxContainer
		if not player_hand_container:
			# Try searching recursively
			player_hand_container = _find_node_by_name(self, "PlayerHandContainer") as HBoxContainer
		if player_hand_container:
			print("BattleUI: Found PlayerHandContainer at alternate path: ", player_hand_container.get_path())
		else:
			push_warning("BattleUI: PlayerHandContainer not found at any path. Searching scene tree...")
			_find_and_print_hbox_containers(self)
	
	# Connect to CardBattleSystem signals
	_connect_signals()
	
	# Connect flee button if it exists
	if flee_button:
		flee_button.pressed.connect(on_flee_pressed)
		flee_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Connect to DeckManager signals
	if not DeckManager.hand_changed.is_connected(_on_hand_changed):
		DeckManager.hand_changed.connect(_on_hand_changed)
	
	# Initialize UI - wait a frame to ensure scene tree is ready
	await get_tree().process_frame
	update_all()

func _connect_signals():
	if not card_battle_system:
		return
	
	# Connect resource signals
	if not card_battle_system.water_changed.is_connected(_on_water_changed):
		card_battle_system.water_changed.connect(_on_water_changed)
	if not card_battle_system.fire_changed.is_connected(_on_fire_changed):
		card_battle_system.fire_changed.connect(_on_fire_changed)
	if not card_battle_system.earth_changed.is_connected(_on_earth_changed):
		card_battle_system.earth_changed.connect(_on_earth_changed)
	if not card_battle_system.air_changed.is_connected(_on_air_changed):
		card_battle_system.air_changed.connect(_on_air_changed)
	
	# Connect other signals
	if not card_battle_system.life_changed.is_connected(_on_life_changed):
		card_battle_system.life_changed.connect(_on_life_changed)
	if not card_battle_system.turn_changed.is_connected(_on_turn_changed):
		card_battle_system.turn_changed.connect(_on_turn_changed)

func update_all():
	# Update all UI elements
	update_counters()
	update_resources()
	update_life()
	update_turn()
	update_hand()

func update_counters():
	# Update deck and discard counters
	if deck_label:
		deck_label.text = str(DeckManager.get_deck_remaining())
	if discard_label:
		discard_label.text = str(DeckManager.get_discard_size())

func update_resources():
	# Update elemental resource displays
	if not card_battle_system:
		return
	
	if water_label:
		water_label.text = str(card_battle_system.get_water())
	if fire_label:
		fire_label.text = str(card_battle_system.get_fire())
	if earth_label:
		earth_label.text = str(card_battle_system.get_earth())
	if air_label:
		air_label.text = str(card_battle_system.get_air())

func update_life():
	# Update life counter
	if not card_battle_system:
		return
	if life_label:
		life_label.text = str(card_battle_system.get_life()) + "/" + str(card_battle_system.get_max_life())

func update_turn():
	# Update turn counter
	if not card_battle_system:
		return
	if turn_label:
		turn_label.text = str(card_battle_system.get_turn_number())

func update_hand():
	# Update player's hand display
	if not player_hand_container:
		push_warning("PlayerHandContainer not found! Cannot display cards.")
		return
	
	# Clear existing cards
	for child in player_hand_container.get_children():
		child.queue_free()
	
	# Get current hand
	var hand = DeckManager.get_hand()
	
	# Debug output
	print("BattleUI.update_hand(): Hand size = ", hand.size())
	print("BattleUI.update_hand(): PlayerHandContainer found = ", player_hand_container != null)
	if player_hand_container:
		print("BattleUI.update_hand(): PlayerHandContainer path = ", player_hand_container.get_path())
	
	# Instantiate cards from hand
	for i in range(hand.size()):
		var card_resource = hand[i]
		if not card_resource:
			continue
		
		# Get card scene path (use default if not set)
		var card_scene_path = card_resource.scene_path
		if card_scene_path.is_empty():
			card_scene_path = DEFAULT_CARD_SCENE
		
		# Load and instantiate card scene
		if ResourceLoader.exists(card_scene_path):
			var card_scene = load(card_scene_path) as PackedScene
			if card_scene:
				var card_instance = card_scene.instantiate()
				player_hand_container.add_child(card_instance)
				print("BattleUI: Instantiated card ", i, " from scene: ", card_scene_path)
				
				# If the card instance has a set_card method (CardUI component), use it
				if card_instance.has_method("set_card"):
					card_instance.set_card(card_resource)
					# Connect card click signal if available
					if card_instance.has_signal("card_clicked"):
						card_instance.card_clicked.connect(_on_card_clicked.bind(i))
					print("BattleUI: Card ", i, " set_card called directly on instance")
				else:
					# Try to find CardUI component in the instance
					var card_ui = card_instance.get_node_or_null("CardUI") as CardUI
					if not card_ui:
						# Search for CardUI in children
						card_ui = _find_card_ui(card_instance)
					if card_ui:
						card_ui.set_card(card_resource)
						if card_ui.has_signal("card_clicked"):
							card_ui.card_clicked.connect(_on_card_clicked.bind(i))
						print("BattleUI: Card ", i, " set_card called on CardUI component")
					else:
						push_warning("BattleUI: No set_card method or CardUI component found on card instance ", i)
			else:
				push_warning("Failed to load card scene: " + card_scene_path)
		else:
			push_warning("Card scene not found: " + card_scene_path)

func _find_card_ui(node: Node) -> CardUI:
	# Recursively search for CardUI component
	if node is CardUI:
		return node as CardUI
	
	for child in node.get_children():
		var result = _find_card_ui(child)
		if result:
			return result
	
	return null

func _on_card_clicked(card_index: int):
	# Handle card click - try to play the card
	if card_battle_system:
		card_battle_system.play_card(card_index)

# Signal handlers
func _on_water_changed(amount: int):
	if water_label:
		water_label.text = str(amount)

func _on_fire_changed(amount: int):
	if fire_label:
		fire_label.text = str(amount)

func _on_earth_changed(amount: int):
	if earth_label:
		earth_label.text = str(amount)

func _on_air_changed(amount: int):
	if air_label:
		air_label.text = str(amount)

func _on_life_changed(current: int, max_life: int):
	if life_label:
		life_label.text = str(current) + "/" + str(max_life)

func _on_turn_changed(turn_number: int):
	if turn_label:
		turn_label.text = str(turn_number)

func _on_hand_changed():
	update_hand()
	update_counters()

func _find_card_battle_system(node: Node) -> CardBattleSystem:
	# Recursively search for CardBattleSystem
	if node is CardBattleSystem:
		return node as CardBattleSystem
	
	for child in node.get_children():
		var result = _find_card_battle_system(child)
		if result != null:
			return result
	
	return null

func _find_node_by_name(node: Node, name_to_find: String) -> Node:
	# Recursively search for a node by name
	if node.name == name_to_find:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_name(child, name_to_find)
		if result != null:
			return result
	
	return null

func _find_and_print_hbox_containers(node: Node, depth: int = 0):
	# Debug function to find all HBoxContainers in the scene
	if node is HBoxContainer:
		var indent = ""
		for i in range(depth):
			indent += "  "
		print(indent + "Found HBoxContainer: ", node.get_path(), " (name: ", node.name, ")")
	
	for child in node.get_children():
		_find_and_print_hbox_containers(child, depth + 1)

func on_flee_pressed():
	# End the battle when flee is pressed
	print("Flee selected")
	if card_battle_system:
		# For now, just end the battle
		# In the future, you might want to add flee logic to CardBattleSystem
		card_battle_system.end_battle(false)
	else:
		# Fallback to BattleManager if CardBattleSystem not found
		if BattleManager.current_battle_data:
			BattleManager.attempt_to_flee()

# Legacy methods - kept for compatibility but not used in card battles
func populate_enemies(_units: Array):
	# Card battles don't use units - this is kept for compatibility
	pass

func populate_ally_info_container(_units: Array) -> void:
	# Card battles don't use units - this is kept for compatibility
	pass

func set_active_unit(_u):
	# Card battles don't use units - this is kept for compatibility
	pass
