extends Node
class_name UnitSlot

var slot_number: int
var node: Node

func _init(_slot_number: int, _node: Node3D):
	slot_number = _slot_number
	node = _node
