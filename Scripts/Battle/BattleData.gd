extends Node
class_name BattleData

var ally_units: Array[Unit]
var enemy_units: Array[Unit]

func set_units(allies: Array[Unit], enemies: Array[Unit]):
	ally_units = allies
	enemy_units = enemies
