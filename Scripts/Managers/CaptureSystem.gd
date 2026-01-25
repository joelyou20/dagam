extends Node

# CaptureSystem - Handles capturing creatures/objects and converting them to cards

# Capture success rates and mechanics
var base_capture_chance: float = 0.3  # 30% base chance
var capture_item_bonus: float = 0.2   # Bonus from using capture items

signal capture_attempted(target: Node, success: bool, card: Card)
signal creature_captured(card: Card)

func _ready():
	pass

#region Capture Mechanics

func attempt_capture(target: Node, capture_item: ItemResource = null) -> Card:
	# Attempt to capture a creature or object
	# Returns the captured Card if successful, null otherwise
	
	if not _can_capture(target):
		push_warning("Target cannot be captured: " + str(target))
		capture_attempted.emit(target, false, null)
		return null
	
	# Calculate capture chance
	var capture_chance = base_capture_chance
	if capture_item:
		capture_chance += capture_item_bonus
	
	# Apply modifiers based on target state
	capture_chance = _calculate_capture_chance(target, capture_chance)
	
	# Roll for capture
	var success = randf() < capture_chance
	
	if success:
		var card = _create_card_from_target(target)
		if card:
			DeckManager.add_card_to_collection(card)
			creature_captured.emit(card)
			print("Successfully captured " + target.name + " as a card!")
			capture_attempted.emit(target, true, card)
			return card
		else:
			capture_attempted.emit(target, false, null)
			return null
	else:
		print("Capture attempt failed!")
		capture_attempted.emit(target, false, null)
		return null

func _can_capture(target: Node) -> bool:
	# Check if target can be captured
	# Can capture enemies, NPCs, or special objects
	if target.has_method("get_resource"):
		var resource = target.get_resource()
		if resource is EnemyResource or resource is AllyResource:
			return true
	
	# Check for special captureable objects
	if target.has_meta("captureable"):
		return target.get_meta("captureable")
	
	return false

func _calculate_capture_chance(target: Node, base_chance: float) -> float:
	# Calculate final capture chance with modifiers
	var chance = base_chance
	
	# Health-based modifier (weaker targets easier to capture)
	if target.has_method("get_resource"):
		var resource = target.get_resource()
		if resource is EntityResource:
			var health_percent = float(resource.current_hp) / float(resource.max_hp)
			# Lower health = higher capture chance
			chance += (1.0 - health_percent) * 0.3  # Up to 30% bonus for low health
	
	# Level-based modifier (lower level = easier)
	if target.has_method("get_resource"):
		var resource = target.get_resource()
		if resource is EntityResource:
			var level = resource.level if resource.has("level") else 1
			# Lower level = easier capture
			chance -= (level - 1) * 0.05  # -5% per level above 1
			chance = max(0.05, chance)  # Minimum 5% chance
	
	# Rarity modifier (if target has rarity)
	if target.has_meta("rarity"):
		var rarity = target.get_meta("rarity")
		match rarity:
			CardRarity.Rarity.COMMON:
				chance += 0.1
			CardRarity.Rarity.UNCOMMON:
				pass  # No modifier
			CardRarity.Rarity.RARE:
				chance -= 0.1
			CardRarity.Rarity.EPIC:
				chance -= 0.2
			CardRarity.Rarity.LEGENDARY:
				chance -= 0.3
	
	# Clamp between 5% and 95%
	return clamp(chance, 0.05, 0.95)

func _create_card_from_target(target: Node) -> Card:
	# Create a Card resource from the captured target
	var card = Card.new()
	
	# Get resource from target
	var resource: EntityResource = null
	if target.has_method("get_resource"):
		resource = target.get_resource()
	
	if not resource:
		push_error("Cannot create card: Target has no resource")
		return null
	
	# Set basic card properties
	card.id = resource.id + "_card_" + str(Time.get_ticks_msec())
	card.name = resource.name
	card.description = resource.description
	card.card_image = resource.portrait_texture if resource.portrait_texture else null
	
	# Determine card type and rarity
	card.card_type = Card.CardType.CREATURE
	card.rarity = _determine_card_rarity(resource)
	
	# Set creature stats from resource
	card.creature_stats = {
		"max_hp": resource.max_hp,
		"current_hp": resource.max_hp,  # Start at full HP
		"attack": resource.physical_attack,
		"defense": resource.physical_defense,
		"speed": resource.speed
	}
	
	# Set costs based on stats (stronger cards cost more)
	card.mana_cost = _calculate_mana_cost(resource)
	card.energy_cost = 0  # Can be customized later
	
	# Capture metadata
	card.captured_from_id = resource.id
	card.capture_date = Time.get_datetime_string_from_system()
	
	# Set level from resource
	card.level = resource.level if resource.has("level") else 1
	
	# Add abilities if resource has them
	if resource.has("abilities"):
		card.abilities = resource.abilities.duplicate()
	
	return card

func _determine_card_rarity(resource: EntityResource) -> CardRarity.Rarity:
	# Determine card rarity based on resource stats/level
	var total_power = resource.max_hp + resource.physical_attack + resource.physical_defense + resource.speed
	var level = resource.level if resource.has("level") else 1
	
	# Adjust power by level
	total_power *= (1.0 + (level - 1) * 0.1)
	
	# Rarity thresholds (can be adjusted)
	if total_power >= 200:
		return CardRarity.Rarity.LEGENDARY
	elif total_power >= 150:
		return CardRarity.Rarity.EPIC
	elif total_power >= 100:
		return CardRarity.Rarity.RARE
	elif total_power >= 60:
		return CardRarity.Rarity.UNCOMMON
	else:
		return CardRarity.Rarity.COMMON

func _calculate_mana_cost(resource: EntityResource) -> int:
	# Calculate mana cost based on stats
	var total_power = resource.max_hp + resource.physical_attack + resource.physical_defense + resource.speed
	var level = resource.level if resource.has("level") else 1
	
	# Base cost formula: power / 10, rounded, minimum 1
	var cost = max(1, int(total_power / 10.0))
	
	# Level modifier
	cost += (level - 1) * 2
	
	# Clamp between 1 and 10
	return clamp(cost, 1, 10)

#endregion

#region Utility Functions

func can_capture_target(target: Node) -> bool:
	# Public method to check if a target can be captured
	return _can_capture(target)

func get_capture_chance(target: Node, capture_item: ItemResource = null) -> float:
	# Get the capture chance for a target (for UI display)
	if not _can_capture(target):
		return 0.0
	
	var chance = base_capture_chance
	if capture_item:
		chance += capture_item_bonus
	
	return _calculate_capture_chance(target, chance)

#endregion
