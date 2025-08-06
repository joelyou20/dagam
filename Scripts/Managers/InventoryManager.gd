extends Node

@onready var InventoryUIScene := preload("res://Scenes/UI/Inventory/InventoryUI.tscn") # Change to your actual path

var inventory_ui: InventoryUI = null
var inventory: Inventory = null

func _ready():
	inventory = Inventory.new()
	inventory.initialize(PlayerManager.inventory_slots)

	# Instantiate InventoryUI right away
	inventory_ui = InventoryUIScene.instantiate()
	inventory_ui.inventory_manager = InventoryManager
	inventory_ui.visible = false
	add_child(inventory_ui)
	
func ensure_inventory_ui():
	if inventory_ui == null:
		inventory_ui = InventoryUIScene.instantiate()
		inventory_ui.inventory_manager = self
		get_tree().get_root().add_child(inventory_ui)
		inventory_ui.tree_exited.connect(func(): inventory_ui = null)

func hide_inventory_ui():
	inventory_ui.hide_ui()

func toggle_inventory_ui():
	ensure_inventory_ui()
	inventory_ui.update_slots()
	inventory_ui.toggle()

func add_item(item: ItemResource, amount: int = 1):
	inventory.add_item(item, amount)
	print("Item added to inventory: " + item.name)
	
func remove_item(item: ItemResource, amount: int = -1):
	inventory.remove_item(item, amount)
	
func has_item():
	pass # TODO
	
func use_item(item: ItemResource, quantity_used: int = 1, remove_on_use: bool = true):
	if item.effect_script:
		var effect = item.effect_script.new()
		if effect is ItemEffect:
			effect.run()
		else:
			push_warning("Effect script does not implement ItemEffect")
		
		if remove_on_use:
			inventory.remove_item(item, quantity_used)

func use_item_on_unit(item: ItemResource, target_unit: Unit, quantity_used: int = 1, remove_on_use: bool = true):
	if item.effect_script:
		var effect = item.effect_script.new()
		if effect is ItemEffect:
			effect.run_on_unit(target_unit)
		else:
			push_warning("Effect script does not implement ItemEffect")

		if remove_on_use:
			inventory.remove_item(item, quantity_used)

func get_items() -> Array[InventorySlotData]:
	return inventory.get_items()

func get_usable_items() -> Array[InventorySlotData]:
	var items = inventory.get_items()
	if items.size() > 0:
		return items.filter(func (i: InventorySlotData): return i.item.can_use_in_battle)
	else: 
		return []

func save_inventory() -> Dictionary:
	var result := {}
	var index := 0

	for slot in inventory.slots:
		if not slot.is_empty():
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
