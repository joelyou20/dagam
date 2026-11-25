extends Node

@export_file("*.tscn") var starting_scene_path := "res://Scenes/Environments/Test.tscn"
@export var spawn_point_name := ""

var scene_manager := SceneManager
var menu_manager := MenuManager

func _ready():
	scene_manager.set_black_screen()
	scene_manager.load_scene(starting_scene_path, false, true, spawn_point_name)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		# If any UI is open, let the UI stack handle it
		if UIManager.handle_cancel():
			get_viewport().set_input_as_handled()

			return
		# Otherwise, open Options (or your pause menu)

		menu_manager.set_menu(true, MenuTabs.Tab.OPTIONS)

	if event.is_action_pressed("toggle_party_menu"):
		menu_manager.set_menu(true, MenuTabs.Tab.ADVENTURE)

	if event.is_action_pressed("toggle_equipment_menu"):
		menu_manager.set_menu(true, MenuTabs.Tab.HEX)

	if event.is_action_pressed("toggle_skills_menu"):
		menu_manager.set_menu(true, MenuTabs.Tab.JOURNAL)

	if event.is_action_pressed("toggle_inventory_menu"):
		menu_manager.set_menu(true, MenuTabs.Tab.INVENTORY)

	if event.is_action_pressed("toggle_formation_menu"):
		menu_manager.set_menu(true, MenuTabs.Tab.HEX)

	if event.is_action_pressed("toggle_hex_menu"):
		menu_manager.set_menu(true, MenuTabs.Tab.HEX)
