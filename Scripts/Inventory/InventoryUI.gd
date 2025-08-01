extends CanvasLayer

@export var inventory_manager: Node
@onready var slot_container := $Panel/GridContainer
@onready var slot_scene := preload("res://Scenes/InventorySlot.tscn")

func _ready():
	visible = false

func toggle():
	visible = !visible
	if visible:
		update_slots()

func update_slots():
	for child in slot_container.get_children():
		child.queue_free()
		
	for slot_data in inventory_manager.inventory.slots:
		if slot_data.item != null:
			var slot_ui = slot_scene.instantiate()
			slot_ui.initialize()
			slot_ui.set_item(slot_data.item, slot_data.quantity)
			connect_slot_signals(slot_ui)
			slot_container.add_child(slot_ui)

func connect_slot_signals(slot: InventorySlot):
	slot.connect("slot_clicked", Callable(self, "_on_slot_clicked"))

func _on_slot_clicked(slot):
	if slot.item.effect_script:
		var effect = slot.item.effect_script.new()
		if effect is ItemEffect:
			effect.run()
		else:
			push_warning("Effect script does not implement ItemEffect")
