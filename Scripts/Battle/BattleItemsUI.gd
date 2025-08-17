extends UIBase
class_name BattleItemsUI

@onready var vbox_container: VBoxContainer = $Panel/VBoxContainer
@onready var slot_scene := preload("res://Scenes/UI/InventorySlot.tscn")
@onready var item_description_ui = $Panel/ItemDescriptionUI as ItemDescriptionUI

# The list of items to show (pass in from BattleUI)
var items: Array[ItemResource] = []

func _ready():
	clear_ui()

func clear_ui():
	for child in vbox_container.get_children():
		child.queue_free()

func update_ui():
	clear_ui()

	var slot_data_list: Array[InventorySlotData] = InventoryManager.get_usable_items()
	
	for slot_data in slot_data_list:
		var slot = slot_scene.instantiate()
		slot.set_item(slot_data.item, slot_data.quantity) # Assuming InventorySlot supports this
		slot.connect("slot_clicked", Callable(self, "_on_slot_clicked"))
		slot.mouse_entered.connect(func(): _on_item_hover(slot))
		slot.mouse_exited.connect(func(): _on_unhover(slot))
		
		vbox_container.add_child(slot)

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
	_on_item_selected(slot_item)
	
func _on_item_selected(item: ItemResource):
	var action := BattleAction.new(
		BattleManager.get_active_unit_slot(),
		BattleAction.ActionType.ITEM
	)
	action.set_item(item)

	BattleManager.start_targeting(action)
	visible = false
