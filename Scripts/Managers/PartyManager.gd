# PartyManager.gd
extends Node

# List of party members (can include PlayerData or AllyResource)
var party: Array[AllyResource] = []  # Use PlayerData, AllyResource, etc.

# TODO: Improve this
func get_party(include_player: bool = true) -> Array:
	if include_player:
		var player = PlayerManager.player
		return party.filter(func(member): return member != player)
	return party

func add_member(member: AllyResource):
	if not party.has(member):
		party.append(member)
		print(member.name + " has joined the party!")

func remove_member(member: AllyResource):
	party.erase(member)
