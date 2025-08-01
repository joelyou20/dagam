extends Node

var inventory: Inventory = null

func _ready():
	inventory = Inventory.new()
	inventory.initialize(PlayerManager.inventory_slots)

func add_item(item: ItemResource, amount: int = 1):
	inventory.add_item(item, amount)
	print("Item added to inventory: " + item.name)
	
func remove_item():
	pass # TODO
	
func has_item():
	pass # TODO
	
func use_item():
	pass # TODO
	
func get_item():
	pass # TODO

func save_inventory() -> Dictionary:
	var result := {}
	var index := 0

	for slot in inventory.slots:
		if not slot.is_empty():
			print("Saving:", slot.item.resource_path, "x", slot.quantity)
			result[str(index)] = {
				"item_path": slot.item.resource_path,
				"quantity": slot.quantity
			}
			index += 1

	return result

func load_inventory(data: Dictionary):
	inventory = Inventory.new()
	inventory.initialize(PlayerManager.inventory_slots)
	
	for key in data.keys():
		var slot_data = data[key]
		var item_path = slot_data.get("item_path", "")
		var quantity = slot_data.get("quantity", 0)

		if item_path != "" and quantity > 0:
			var item_resource = load(item_path)
			if item_resource:
				inventory.add_item(item_resource, quantity)
				print("Loaded item:", item_resource.resource_path, "x", quantity)
