extends Node

@onready var dialog_box := $DialogBox
@onready var menu_ui := $MenuUI
var inventory_ui: CanvasLayer = null

var InventoryUIScene := preload("res://Scenes/InventoryUI.tscn") # Change to your actual path

var menu_open := false

func _ready():
	DialogManager.dialog_box = dialog_box
	await SceneManager.initialize()
	SceneManager.transition_to_scene("res://Scenes/Test.tscn")

	# Instantiate InventoryUI right away
	inventory_ui = InventoryUIScene.instantiate()
	inventory_ui.inventory_manager = InventoryManager
	inventory_ui.visible = false
	add_child(inventory_ui)
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_set_menu_open(!menu_open)

	if event.is_action_pressed("toggle_inventory"):
		_toggle_inventory_ui()

func _set_menu_open(state: bool):
	if menu_open == state:
		return

	menu_open = state
	menu_ui.visible = menu_open
	get_tree().paused = menu_open

	# Also hide inventory if open
	if menu_open and inventory_ui and inventory_ui.visible:
		inventory_ui.visible = false

func _toggle_inventory_ui():
	inventory_ui.toggle()
