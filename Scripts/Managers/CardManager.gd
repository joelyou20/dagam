extends Node

func get_effective_stat(resource: CardResource, stat_name: String) -> int:
	# Returns stat value adjusted by level
	# Note: current_hp doesn't scale, it's the actual current value
	if stat_name == "current_hp":
		return resource.creature_stats.get("current_hp", get_effective_stat(resource, "max_hp"))
	
	if not resource.creature_stats.has(stat_name):
		return 0
	
	var base_stat = resource.creature_stats[stat_name]
	# Simple level scaling: +10% per level
	var multiplier = 1.0 + (resource.level - 1) * 0.1
	return int(base_stat * multiplier)

func reset_creature_hp(resource: CardResource):
	# Reset creature HP to max when summoned
	resource.creature_stats["current_hp"] = get_effective_stat(resource, "max_hp")

func can_play(resource: CardResource, available_water: int, available_fire: int, available_earth: int, available_air: int) -> bool:
	# Check if player has enough elemental resources to play the card
	return available_water >= resource.water_cost and \
		   available_fire >= resource.fire_cost and \
		   available_earth >= resource.earth_cost and \
		   available_air >= resource.air_cost

func add_experience(resource: CardResource, amount: int) -> bool:
	# Returns true if leveled up
	resource.experience += amount
	if resource.experience >= resource.experience_to_next_level:
		level_up(resource)
		return true
	return false

func level_up(resource: CardResource):
	resource.experience -= resource.experience_to_next_level
	resource.level += 1
	resource.experience_to_next_level = int(resource.experience_to_next_level * 1.2)  # 20% increase per level
	print(resource.name + " leveled up to level " + str(resource.level) + "!")

func duplicate_card(resource: CardResource) -> CardResource:
	var new_card = resource.duplicate()
	new_card.id = resource.id + "_" + str(Time.get_ticks_msec())  # Unique ID for duplicate
	return new_card
