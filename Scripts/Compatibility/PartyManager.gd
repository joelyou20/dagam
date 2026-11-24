extends Node
## Compatibility bridge for existing dialogue actions and old save files.
## New gameplay uses CompanionManager and solo player progression.

var party: Array[AllyResource]:
	get:
		return get_party(false)

func get_party(include_player: bool = true) -> Array[AllyResource]:
	var result: Array[AllyResource] = []

	if include_player:
		result.append(PlayerManager.player)

	for member in CompanionManager.members:
		var resource = CompanionManager.get_resource(member.id)

		if resource != null:
			result.append(resource)

	return result

func add_member(member: AllyResource) -> void:
	CompanionManager.recruit(member)

func remove_member(member: AllyResource) -> void:
	if member != null:
		CompanionManager.remove_companion(member.id)

func get_member_by_id(id: String) -> Resource:
	for member in get_party():
		if member.id == id:
			return member

	return null

func get_member_at_index(index: int) -> AllyResource:
	var members = get_party()

	return members[index] if index >= 0 and index < members.size() else null

func grant_xp(amount: int) -> void:
	PlayerManager.add_xp(amount)

func get_ally_equipment(_ally: AllyResource) -> Array[EquipmentResource]:
	return []

func save_party() -> Array[Dictionary]:
	return CompanionManager.save_companions()

func load_party(data: Array[Dictionary]) -> void:
	CompanionManager.load_companions(data)
