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
