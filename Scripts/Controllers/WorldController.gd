extends Node

func _ready():
	SceneManager.transition_to_scene("res://Scenes/Environments/Test.tscn")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		MenuManager.toggle_menu()

	if event.is_action_pressed("toggle_inventory"):
		InventoryManager.toggle_inventory_ui()
