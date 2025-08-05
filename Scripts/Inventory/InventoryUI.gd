extends UIBase
class_name InventoryUI

@export var inventory_manager: Node
@onready var slot_container := $Panel/GridContainer
@onready var slot_scene := preload("res://Scenes/UI/Inventory/InventorySlot.tscn")

func update_slots():
	for child in slot_container.get_children():
		child.queue_free()
		
	for slot_data in inventory_manager.inventory.slots:
		if slot_data.item != null:
			var slot_ui = slot_scene.instantiate()
			connect_slot_signals(slot_ui)
			slot_container.add_child(slot_ui)
			
			slot_ui.call_deferred("set_item", slot_data.item, slot_data.quantity)

func connect_slot_signals(slot: InventorySlot):
	slot.connect("slot_clicked", Callable(self, "_on_slot_clicked"))

func _on_slot_clicked(slot: InventorySlot):
	var slot_item = slot.get_item()
	InventoryManager.use_item(slot_item)
	InventoryManager.remove_item(slot_item, 1)
	update_slots()
