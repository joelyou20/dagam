extends UIBase
class_name ChestUI

signal take_all_pressed
signal slot_clicked(item: ItemResource, index: int)

@onready var take_all_btn: Button = $Panel/TakeAllButton
@onready var close_btn: Button = $Panel/CloseButton
@onready var loot_container = $Panel/LootContainer
@onready var inventory_slot_scene := preload("res://Scenes/UI/InventorySlot.tscn")

@onready var item_description_ui = $ItemDescriptionUI as ItemDescriptionUI

func _ready() -> void:
	# Basic wiring
	take_all_btn.pressed.connect(_on_take_all_pressed)
	close_btn.pressed.connect(_on_close_pressed)

	# Good defaults for overlay UIs
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func populate_loot(loot: Array[ItemResource]):
	for item in loot:
		var loot_slot = inventory_slot_scene.instantiate() as InventorySlot
		
		loot_slot.set_item(item, 1)
		loot_slot.connect("slot_clicked", Callable(self, "_on_slot_clicked"))
		loot_slot.mouse_entered.connect(func(): _on_item_hover(loot_slot))
		loot_slot.mouse_exited.connect(func(): _on_unhover(loot_slot))
		loot_container.add_child(loot_slot)

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
	loot_container.remove_child(slot)
	slot_clicked.emit(slot.get_item(), slot.get_index())

func _on_take_all_pressed():
	take_all_pressed.emit()

func _on_close_pressed():
	hide_ui()
