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

func use_item(item: ItemResource, target_resource: EntityResource = null):
	if item is ConsumableResource:
		use_consumable(item, target_resource)
	#if item is EquipmentResource:
		#EquipmentManager.equip_item(item)

func use_consumable(item: ItemResource, target_resource: EntityResource = null):
	var item_used_successfully: bool = false
	if item.effect_script:
		var effect = item.effect_script.new()
		if effect is ItemEffect:
			item_used_successfully = effect.run(target_resource)
		else:
			push_warning("Effect script does not implement ItemEffect")
		
		if item_used_successfully:
			remove_item(item, 1)

# --- Retrieval ---
func get_items() -> Array[InventorySlotData]:
	return _inventory.get_items()

func get_usable_items() -> Array[InventorySlotData]:
	var items: Array[InventorySlotData] = _inventory.get_items()
	return items.filter(func(i: InventorySlotData): return i.item is not EquipmentResource and i.item.can_use_in_battle)

func get_inventory() -> Inventory:
	return _inventory

# --- Saving / Loading ---
func save_inventory() -> Dictionary:
	var result := {}
	var index := 0

	for slot in _inventory.slots:
		if not slot.is_empty():
			result[str(index)] = {
				"item_path": slot.item.resource_path,
				"quantity": slot.quantity
			}
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
