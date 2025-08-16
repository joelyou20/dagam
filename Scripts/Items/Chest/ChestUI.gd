extends UIBase
class_name ChestUI

signal take_all_pressed
signal close_requested
signal slot_clicked(item: ItemResource, index: int)

@onready var take_all_btn: Button = $Panel/TakeAllButton
@onready var close_btn: Button = $Panel/CloseButton
@onready var loot_container = $Panel/LootContainer
var inventory_slot_scene := preload("res://Scenes/UI/Inventory/InventorySlot.tscn")

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
		loot_container.add_child(loot_slot)

func _on_slot_clicked(slot: InventorySlot):
	loot_container.remove_child(slot)
	slot_clicked.emit(slot.get_item(), slot.get_index())

func _on_take_all_pressed():
	take_all_pressed.emit()

func _on_close_pressed():
	hide_ui()
