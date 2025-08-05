# InventorySlotData.gd
extends Resource
class_name InventorySlotData

@export var item: ItemResource = null
@export var quantity: int = 0

func is_empty() -> bool:
	var result = item == null or quantity <= 0
	return result

func can_stack(new_item: ItemResource) -> bool:
	var result = item != null and item == new_item and item.stackable and quantity < item.max_stack
	return result
