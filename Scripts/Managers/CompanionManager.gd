extends Node
## Story companions are recruitment records, not combatants or equipment holders.
signal companions_changed

var members: Array[Dictionary] = []
var _resources: Dictionary = {}


func recruit(member: AllyResource, hide_npc: bool = true) -> bool:
	if member == null or member.id.is_empty() or has_companion(member.id):
		return false

	var record = {
		"id": member.id,
		"name": member.name,
		"description": member.description,
		"resource_path": member.resource_path,
		"hide_npc": hide_npc,
	}
	members.append(record)
	_resources[member.id] = member.duplicate(true)
	companions_changed.emit()
	return true


func has_companion(id: String) -> bool:
	return members.any(func(member): return member.id == id)


func should_hide_npc(id: String) -> bool:
	for member in members:
		if member.id == id:
			return bool(member.get("hide_npc", true))
	return false


func remove_companion(id: String) -> void:
	members = members.filter(func(member): return member.id != id)
	_resources.erase(id)
	companions_changed.emit()


func get_resource(id: String) -> AllyResource:
	if _resources.has(id):
		return _resources[id]
	for member in members:
		if member.id != id:
			continue
		var path: String = member.get("resource_path", "")
		if ResourceLoader.exists(path):
			var source = load(path)
			if source is AllyResource:
				_resources[id] = source.duplicate(true)
				return _resources[id]
	return null


func save_companions() -> Array[Dictionary]:
	return members.duplicate(true)


func load_companions(data: Array) -> void:
	members.clear()
	_resources.clear()
	for value in data:
		if not value is Dictionary or str(value.get("id", "")).is_empty():
			continue
		if not has_companion(str(value.id)):
			# Preserve legacy fields without applying their old combat/equipment effects.
			members.append(value.duplicate(true))
	_remove_recruited_npcs()
	companions_changed.emit()


func _remove_recruited_npcs() -> void:
	for npc in get_tree().get_nodes_in_group("NPC"):
		if npc is NPC and should_hide_npc(npc.id):
			npc.queue_free()
