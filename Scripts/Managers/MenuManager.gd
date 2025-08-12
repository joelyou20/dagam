extends Node

@onready var MenuUIScene := preload("res://Scenes/UI/MenuUI.tscn")

var menu_ui: MenuUI = null
var current_tab: MenuTabs.Tab = MenuTabs.Tab.UNSET
var current_party_member_menu_index: int = 0

signal party_tab_open
signal equipment_tab_open
signal skills_tab_open
signal inventory_tab_open
signal formation_tab_open
signal options_tab_open

func hide_menu():
	set_menu(false)
	
func set_current_party_member_menu_index(index: int):
	current_party_member_menu_index = index

func toggle_menu(tab: MenuTabs.Tab = MenuTabs.Tab.UNSET):
	var menu_open = menu_ui and menu_ui.visible
	set_menu(!menu_open, tab)

func set_menu(state: bool, tab: MenuTabs.Tab = MenuTabs.Tab.UNSET):
	if tab == MenuTabs.Tab.UNSET:
		menu_ui.hide_ui()
		return
	
	ensure_menu_ui()
	var change_tab = current_tab == MenuTabs.Tab.UNSET or current_tab != tab
	if state or change_tab:
		current_tab = tab
		menu_ui.show_panel(tab)
	else:
		current_tab = MenuTabs.Tab.UNSET
		menu_ui.hide_ui()

func ensure_menu_ui():
	if menu_ui == null:
		menu_ui = MenuUIScene.instantiate()
		menu_ui.visible = false
		get_tree().get_root().add_child(menu_ui)
		menu_ui.tree_exited.connect(func(): menu_ui = null)
