extends UIBase
class_name InventoryMenuUI

@onready var slot_container := $Panel/GridContainer
@onready var slot_scene := preload("res://Scenes/UI/InventorySlot.tscn")

@onready var item_description_ui = $ItemDescriptionUI as ItemDescriptionUI

func update_slots():
	for child in slot_container.get_children():
		child.queue_free()
		
	var inventory = InventoryManager.get_inventory()
	
	if not inventory:
		push_error("Inventory is not set.")
		return
		
	for slot_data in inventory.slots:
		if slot_data.item != null:
			var slot_ui = slot_scene.instantiate()
			connect_slot_signals(slot_ui)
			slot_container.add_child(slot_ui)
			
			slot_ui.call_deferred("set_item", slot_data.item, slot_data.quantity)

func connect_slot_signals(slot: InventorySlot):
	slot.connect("slot_clicked", Callable(self, "_on_slot_clicked"))
	slot.mouse_entered.connect(func(): _on_item_hover(slot))
	slot.mouse_exited.connect(func(): _on_unhover(slot))

func _on_item_hover(slot: InventorySlot):
	# Add black border on hover
	if slot.has_node("HoverBorder"):
		slot.get_node("HoverBorder").visible = true
		
	var item = slot.get_item()
	
	item_description_ui.call_deferred("show")
	item_description_ui.call_deferred("set_item", item)
	
func _on_unhover(slot: InventorySlot):
	# Add black border on hover
	if slot.has_node("HoverBorder"):
		slot.get_node("HoverBorder").visible = false
		
	item_description_ui.call_deferred("hide")
	
func _on_slot_clicked(slot: InventorySlot):
	var slot_item = slot.get_item()
	InventoryManager.use_item(slot_item)
	update_slots()
