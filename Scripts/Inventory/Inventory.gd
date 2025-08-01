# Inventory.gd
extends Node3D
class_name Inventory

@export var slots: Array[InventorySlotData] = []

func initialize(slot_count: int):
	slots.clear()
	for i in slot_count:
		var slot := InventorySlotData.new()
		slots.append(slot)

func add_item(new_item: ItemResource, amount: int = 1) -> bool:
	var first_empty_slot : InventorySlotData = null

	for slot in slots:
		if slot.can_stack(new_item):
			var space = new_item.max_stack - slot.quantity
			var to_add = min(space, amount)
			slot.quantity += to_add
			amount -= to_add
			if amount <= 0:
				return true

		elif slot.is_empty() and first_empty_slot == null:
			first_empty_slot = slot

	if amount > 0 and first_empty_slot != null:
		first_empty_slot.item = new_item
		first_empty_slot.quantity = amount
		return true

	return false
