extends Node

var _inventory: Inventory = null


func _ready():
	_inventory = Inventory.new()
	_inventory.initialize(PlayerManager.player.inventory_slots)


# --- Item Management ---
func add_item(item: ItemResource, amount: int = 1):
	_inventory.add_item(item, amount)
	print("Item added to inventory: " + item.name)


# --- Item Management ---
func add_item_array(items: Array[ItemResource]):
	for item in items:
		_inventory.add_item(item)


func remove_item(item: ItemResource, amount: int = -1):
	_inventory.remove_item(item, amount)


func has_item(item: ItemResource) -> bool:
	return _inventory.has_item(item)


func use_item(item: ItemResource, target_resource: EntityResource = null) -> bool:
	if HexManager.is_battle_open() or item == null or not has_item(item):
		return false
	if item is ConsumableResource:
		return use_consumable(
			item, target_resource if target_resource != null else PlayerManager.player
		)
	return false


func use_consumable(item: ItemResource, target_resource: EntityResource = null) -> bool:
	if not item is ConsumableResource or item.effect_script == null or not has_item(item):
		return false
	var effect = item.effect_script.new()
	var used = effect is ItemEffect and effect.run(target_resource)
	if effect is Object and not effect is RefCounted:
		effect.free()
	if used:
		remove_item(item, 1)
	return used


# --- Retrieval ---
func get_items() -> Array[InventorySlotData]:
	return _inventory.get_items()


func get_usable_items() -> Array[InventorySlotData]:
	var items: Array[InventorySlotData] = _inventory.get_items()
	return items.filter(
		func(i: InventorySlotData):
			return i.item is not EquipmentResource and i.item.can_use_in_battle
	)


func get_inventory() -> Inventory:
	return _inventory


# --- Saving / Loading ---
func save_inventory() -> Dictionary:
	var result := {}
	var index := 0

	for slot in _inventory.slots:
		if not slot.is_empty():
			result[str(index)] = {"item_path": slot.item.resource_path, "quantity": slot.quantity}
			index += 1

	return result


func load_inventory(data: Dictionary):
	_inventory = Inventory.new()
	_inventory.initialize(PlayerManager.player.inventory_slots)

	for key in data.keys():
		var slot_data = data[key]
		var item_path = slot_data.get("item_path", "")
		var quantity = slot_data.get("quantity", 0)

		if item_path != "" and quantity > 0:
			var item_resource = load(item_path)
			if item_resource:
				_inventory.add_item(item_resource, quantity)
