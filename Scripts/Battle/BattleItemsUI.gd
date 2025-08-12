extends UIBase
class_name BattleItemsUI

@onready var vbox_container: VBoxContainer = $Panel/VBoxContainer
@onready var preview_sprite: Sprite2D = $Panel/GridContainer/HBoxContainer2/SpritePlaceholder/Sprite2D
@onready var name_label: Label = $Panel/GridContainer/HBoxContainer2/NameLabel
@onready var effect_container: Container = $Panel/GridContainer/EffectContainer
@onready var slot_scene := preload("res://Scenes/UI/Inventory/InventorySlot.tscn")

# The list of items to show (pass in from BattleUI)
var items: Array[ItemResource] = []

func _ready():
	clear_ui()

func clear_ui():
	for child in vbox_container.get_children():
		child.queue_free()
	preview_sprite.texture = null
	name_label.text = ""
	for c in effect_container.get_children():
		c.queue_free()

func update_ui():
	clear_ui()

	var slot_data_list: Array[InventorySlotData] = InventoryManager.get_usable_items()
	
	for slot_data in slot_data_list:
		var slot = slot_scene.instantiate()
		slot.set_item(slot_data.item, slot_data.quantity) # Assuming InventorySlot supports this
		slot.connect("slot_clicked", Callable(self, "_on_slot_clicked"))
		slot.mouse_entered.connect(func(): _on_item_hover(slot))
		
		vbox_container.add_child(slot)

func _on_item_hover(slot: InventorySlot):
	# Add black border on hover
	if slot.has_node("HoverBorder"):
		slot.get_node("HoverBorder").visible = true
		
	var item = slot.get_item()
	# Update right-hand preview box
	preview_sprite.texture = item.icon
	preview_sprite.scale = Vector2(0.75, 0.75) # Adjust to your desired size
	name_label.text = item.name

	# Clear old effect content
	for c in effect_container.get_children():
		c.queue_free()

	# Add description
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	desc_label.add_theme_color_override("font_color", Color.BLACK)
	effect_container.add_child(desc_label)

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
