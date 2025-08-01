extends Node

var experience: int = 0
var inventory_slots: int = 10
var health_points: int = 100
	
func add_xp(amount: int):
	experience += amount
	
func add_hp(amount: int):
	set_hp(health_points + amount)
	
func set_hp(amount: int):
	health_points = amount
	print("Player health is now: " + str(health_points))
	
func get_player_node() -> Node3D:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		return players[0]
	return null
