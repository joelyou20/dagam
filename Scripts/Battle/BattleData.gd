extends Node
class_name BattleData

var ally_units: Array[Unit]
var enemy_units: Array[Unit]
var was_fled: bool = false
var xp_reward: int = 0
var flee_chance: float = 0

func set_units(allies: Array[Unit], enemies: Array[Unit]):
	ally_units = allies
	enemy_units = enemies
	
func set_xp_reward():
	if enemy_units:
		for enemy in enemy_units:
			xp_reward += enemy.resource.xp_reward
