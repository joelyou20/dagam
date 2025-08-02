extends Node
class_name UnitSlot

enum UnitSlotType {
	ALLY,
	ENEMY
}

var slot_number: int
var node: Node
var type: UnitSlotType

func _init(_slot_number: int, _node: Node3D, _type: UnitSlotType):
	slot_number = _slot_number
	node = _node
	type = _type
