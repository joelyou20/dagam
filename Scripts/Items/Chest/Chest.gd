extends Interactable
class_name Chest

var is_open := false
var chest_ui_scene := preload("res://Scenes/UI/ChestUI.tscn")
var chest_ui: ChestUI = null

@export var loot: Array[ItemResource] = []

func _on_interact() -> void:
	if not is_open:
		is_open = true
		$ChestClosedSprite.hide()
		$ChestOpenSprite.show()

	if loot.size() > 0:
		_show_chest_ui()

func _show_chest_ui() -> void:
	if chest_ui and is_instance_valid(chest_ui):
		# Already open; bring to front
		chest_ui.show()
		return

	chest_ui = chest_ui_scene.instantiate() as ChestUI

	# Mount under a UI layer or the tree root
	var ui_parent: Node = null
	if has_node("/root/World/UI"):
		ui_parent = get_node("/root/World/UI")   # your CanvasLayer
	else:
		ui_parent = get_tree().root              # safe fallback

	ui_parent.add_child(chest_ui)

	# Connect signals once
	chest_ui.take_all_pressed.connect(_on_take_all_pressed)
	chest_ui.slot_clicked.connect(_on_slot_clicked)
	
	chest_ui.populate_loot(loot)

func _on_slot_clicked(item: ItemResource, index: int):
	InventoryManager.add_item(item)
	loot.remove_at(index)
	
	if loot.is_empty():
		chest_ui.hide_ui()

func _on_take_all_pressed():
	InventoryManager.add_item_array(loot)
	loot.clear()
	_close_chest_ui()

func _on_chest_close_requested():
	_close_chest_ui()

func _close_chest_ui():
	if chest_ui and is_instance_valid(chest_ui):
		chest_ui.queue_free()
		chest_ui = null
		
func _unhandled_input(event: InputEvent) -> void:
	if not chest_ui:
		return
	
	if event.is_action_pressed("take_all"):
		_on_take_all_pressed()
		get_viewport().set_input_as_handled()
