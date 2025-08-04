extends Node

var scene_manager := SceneManager
var menu_manager := MenuManager
var inventory_manager := InventoryManager

func _ready():
	scene_manager.set_black_screen()
	scene_manager.load_scene("res://Scenes/Environments/Test.tscn", false, true)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		menu_manager.toggle_menu()

	if event.is_action_pressed("toggle_inventory"):
		inventory_manager.toggle_inventory_ui()
