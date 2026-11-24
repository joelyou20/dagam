extends Node
## Legacy signal contract only. Hex owns its player/enemy turn sequence.
signal turn_advanced(previous: int, next: int)

var battle_time := 0.0
var turn_order_queue: Array[String] = []

func setup(_units: Array[Unit]) -> void:
	pass

func update(_units: Array[Unit]) -> void:
	pass

func finish_turn(_unit: Unit) -> String:
	return ""

func remove_from_turn_order(_id: String) -> void:
	pass
