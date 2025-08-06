extends Node

var scene_manager := SceneManager
var menu_manager := MenuManager

func _ready():
	scene_manager.set_black_screen()
	scene_manager.load_scene("res://Scenes/Environments/Test.tscn", false, true)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		menu_manager.toggle_menu(MenuTabs.Tab.OPTIONS)
	if event.is_action_pressed("toggle_party_menu"):
		menu_manager.toggle_menu(MenuTabs.Tab.PARTY)
	if event.is_action_pressed("toggle_skills_menu"):
		menu_manager.toggle_menu(MenuTabs.Tab.SKILLS)
	if event.is_action_pressed("toggle_inventory_menu"):
		menu_manager.toggle_menu(MenuTabs.Tab.INVENTORY)
	if event.is_action_pressed("toggle_formation_menu"):
		menu_manager.toggle_menu(MenuTabs.Tab.FORMATION)
