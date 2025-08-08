# PartyManager.gd
extends Node

# List of party members (can include PlayerResource or AllyResource)
var party: Array[AllyResource] = []  # Use PlayerResource, AllyResource, etc.

# TODO: Improve this
func get_party(include_player: bool = true) -> Array[AllyResource]:
	if include_player:
		var party_with_player = party.duplicate()
		party_with_player.append(PlayerManager.player)
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

func remove_member(member: AllyResource):
	party.erase(member)
	
func grant_xp(total_xp: int):
	var current_party = get_party(true)
	
	@warning_ignore("integer_division")
	var xp_each: int = floor(total_xp / current_party.size())
	
	for member in current_party:
		print(member.name + " gained " + str(xp_each) + " experience!")
		_add_xp_to_member(member, xp_each)
		print(member.name + " needs " + str(member.xp_to_next_level - member.experience) + " experience to level up!")

func _add_xp_to_member(member: Resource, amount: int):
	member.experience += amount
	while member.experience >= member.xp_to_next_level:
		member.experience -= member.xp_to_next_level
		member.level += 1
		member.xp_to_next_level = int(member.xp_to_next_level * member.xp_growth_rate)
		
		# Optional: Increase stats on level up
		member.max_hp += 5
		member.attack_power += 1
		member.current_hp = member.max_hp  # Heal on level-up
		
		print("%s leveled up to %d!" % [member.name, member.level])

# --- SAVE / LOAD ---

func save_party() -> Array[Dictionary]:
	var saved_members: Array[Dictionary] = []
	for member in party:
		var member_data := {
			"resource_path": member.resource_path, # custom property or add if missing
			"id": member.id,
			"name": member.name,
			"level": member.level,
			"experience": member.experience,
			"current_hp": member.current_hp,
			"max_hp": member.max_hp,
			"attack_power": member.attack_power,
			"speed": member.speed,
			"slot_number": member.slot_number,
			"battle_scale": member.battle_scale,
			"xp_to_next_level": member.xp_to_next_level,
			"xp_growth_rate": member.xp_growth_rate,
			"visual_scene": member.visual_scene.resource_path if member.visual_scene else "",
			"portrait_texture": member.portrait_texture.resource_path if member.portrait_texture else ""
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
		member.level = data.get("level", member.level)
		member.experience = data.get("experience", member.experience)
		member.current_hp = data.get("current_hp", member.current_hp)
		member.max_hp = data.get("max_hp", member.max_hp)
		member.attack_power = data.get("attack_power", member.attack_power)
		member.speed = data.get("speed", member.speed)
		member.slot_number = data.get("slot_number", member.slot_number)
		member.battle_scale = data.get("battle_scale", member.battle_scale)
		member.xp_to_next_level = data.get("xp_to_next_level", member.xp_to_next_level)
		member.xp_growth_rate = data.get("xp_growth_rate", member.xp_growth_rate)

		var scene_path = data.get("visual_scene", "")
		if scene_path != "":
			member.visual_scene = load(scene_path)

		var texture_path = data.get("portrait_texture", "")
		if texture_path != "":
			member.portrait_texture = load(texture_path)

		party.append(member)
