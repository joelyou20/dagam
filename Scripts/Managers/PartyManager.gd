# PartyManager.gd
extends Node

# List of party members (can include PlayerResource or AllyResource)
var party: Array[AllyResource] = []  # Use PlayerResource, AllyResource, etc.

# TODO: Improve this
func get_party(include_player: bool = true) -> Array[AllyResource]:
	if include_player:
		var party_with_player = party.duplicate()
		party_with_player.insert(0,PlayerManager.player)
		return party_with_player
	return party
	
func get_member_by_id(id: String) -> Resource:
	for member in get_party():
		if member.id == id:
			return member
	return null

func add_member(member: AllyResource):
	if not party.has(member):
		party.append(member)
		print(member.name + " has joined the party!")

		# Add their starting equipment to the inventory if not already present
		_add_equipment_to_inventory(member.head_equipment)
		_add_equipment_to_inventory(member.chest_equipment)
		_add_equipment_to_inventory(member.back_equipment)
		_add_equipment_to_inventory(member.feet_equipment)
		_add_equipment_to_inventory(member.hands_equipment)
		_add_equipment_to_inventory(member.main_weapon_equipment)
		_add_equipment_to_inventory(member.offhand_weapon_equipment)

func _add_equipment_to_inventory(equip: EquipmentResource):
	if equip != null:
		InventoryManager.add_item(equip, 1)

func remove_member(member: AllyResource):
	party.erase(member)
	
func get_member_at_index(index: int) -> AllyResource:
	var members: Array[AllyResource] = get_party(true)  # includes player at [0]
	if index < 0 or index >= members.size():
		return null
	return members[index]
	
func grant_xp(total_xp: int):
	var current_party = get_party(true)
	
	@warning_ignore("integer_division")
	var xp_each: int = floor(total_xp / current_party.size())
	
	for member in current_party:
		print(member.name + " gained " + str(xp_each) + " experience!")
		_add_xp_to_member(member, xp_each)
		print(member.name + " needs " + str(member.xp_to_next_level - member.experience) + " experience to level up!")

func _add_xp_to_member(member: EntityResource, amount: int):
	member.experience += amount
	while member.experience >= member.xp_to_next_level:
		member.experience -= member.xp_to_next_level
		member.level += 1
		member.xp_to_next_level = int(member.xp_to_next_level * member.xp_growth_rate)
		
		# TODO: UPDATE THIS LATER
		member.max_hp += 5
		member.physical_attack += 1
		member.current_hp = member.max_hp  # Heal on level-up
		
		print("%s leveled up to %d!" % [member.name, member.level])

func get_ally_equipment(ally: AllyResource) -> Array[EquipmentResource]:
	return [
			ally.head_equipment, 
			ally.chest_equipment, 
			ally.back_equipment,
			ally.feet_equipment, 
			ally.hands_equipment,
			ally.main_weapon_equipment, 
			ally.offhand_weapon_equipment
		]

# --- SAVE / LOAD ---

func save_party() -> Array[Dictionary]:
	var saved_members: Array[Dictionary] = []
	for member in party:
		var member_data := {
			"resource_path": member.resource_path, # custom property or add if missing
			"id": member.id,
			"name": member.name,
			"max_hp": member.max_hp,
			"current_hp": member.current_hp,
			"slot_number": member.slot_number,
			"battle_scale": member.battle_scale,
			"visual_scene": member.visual_scene.resource_path,
			"portrait_texture": member.portrait_texture.resource_path,
			
			"level": member.level,
			"experience": member.experience,
			"xp_to_next_level": member.xp_to_next_level,
			"xp_growth_rate": member.xp_growth_rate,
			
			"speed": member.speed,
			"physical_attack": member.physical_attack,
			"physical_defense": member.physical_defense,
			"magical_attack": member.magical_attack,
			"magical_defense": member.magical_defense,
			
			"head_equipment": ResUtil.resource_to_path_or_empty(member.head_equipment),
			"chest_equipment": ResUtil.resource_to_path_or_empty(member.chest_equipment),
			"back_equipment": ResUtil.resource_to_path_or_empty(member.back_equipment),
			"feet_equipment": ResUtil.resource_to_path_or_empty(member.feet_equipment),
			"hands_equipment": ResUtil.resource_to_path_or_empty(member.hands_equipment),
			"main_weapon_equipment": ResUtil.resource_to_path_or_empty(member.main_weapon_equipment),
			"offhand_weapon_equipment": ResUtil.resource_to_path_or_empty(member.offhand_weapon_equipment),
		}
		saved_members.append(member_data)
	return saved_members

func load_party(saved_data: Array[Dictionary]):
	party.clear()

	for data in saved_data:
		var path: String  = data.get("resource_path", "")
		if path == "":
			push_error("Missing resource path for party member.")
			continue

		var member: AllyResource = load(path).duplicate(true) as AllyResource
		if member == null:
			push_error("Failed to load party member from path: " + path)
			continue

		# Apply saved values
		member.id = data.get("id", member.id)
		member.name = data.get("name", member.name)
		member.current_hp = data.get("current_hp", member.current_hp)
		member.max_hp = data.get("max_hp", member.max_hp)
		member.slot_number = data.get("slot_number", member.slot_number)
		member.battle_scale = data.get("battle_scale", member.battle_scale)
		
		member.level = data.get("level", member.level)
		member.experience = data.get("experience", member.experience)
		member.xp_to_next_level = data.get("xp_to_next_level", member.xp_to_next_level)
		member.xp_growth_rate = data.get("xp_growth_rate", member.xp_growth_rate)
		
		member.speed = data.get("speed", member.speed)
		member.physical_attack = data.get("physical_attack", member.physical_attack)
		member.physical_defense = data.get("physical_defense", member.physical_defense)
		member.magical_attack = data.get("magical_attack", member.magical_attack)
		member.magical_defense = data.get("magical_defense", member.magical_defense)
		
		member.head_equipment = ResUtil.to_equipment(data.get("head_equipment"))
		member.chest_equipment = ResUtil.to_equipment(data.get("chest_equipment"))
		member.back_equipment = ResUtil.to_equipment(data.get("back_equipment"))
		member.feet_equipment = ResUtil.to_equipment(data.get("feet_equipment"))
		member.hands_equipment = ResUtil.to_equipment(data.get("hands_equipment"))
		member.main_weapon_equipment = ResUtil.to_equipment(data.get("main_weapon_equipment"))
		member.offhand_weapon_equipment = ResUtil.to_equipment(data.get("offhand_weapon_equipment"))

		var scene_path = data.get("visual_scene", "")
		if scene_path != "":
			member.visual_scene = load(scene_path)

		var texture_path = data.get("portrait_texture", "")
		if texture_path != "":
			member.portrait_texture = load(texture_path)

		party.append(member)
