extends Node

@onready var MenuUIScene := preload("res://Scenes/UI/Menus/MenuUI.tscn")

var menu_ui: MenuUI = null
var current_tab: MenuTabs.Tab = MenuTabs.Tab.UNSET
var current_party_member_menu_index: int = 0

func hide_menu():
	set_menu(false)
	
func set_current_party_member_menu_index(index: int):
	current_party_member_menu_index = index

func set_menu(state: bool, tab: MenuTabs.Tab = MenuTabs.Tab.UNSET):
	if tab == MenuTabs.Tab.UNSET:
		menu_ui.close_menu(tab)
		return
	
	ensure_menu_ui()
	var change_tab = current_tab == MenuTabs.Tab.UNSET or current_tab != tab
	if state and change_tab:
		current_tab = tab
		menu_ui.show_menu(tab)
	else:
		current_tab = MenuTabs.Tab.UNSET
		menu_ui.close_menu(tab)

func ensure_menu_ui():
	if menu_ui == null:
		menu_ui = MenuUIScene.instantiate()
		menu_ui.visible = false
		get_tree().get_root().add_child(menu_ui)
		menu_ui.tree_exited.connect(func(): menu_ui = null)
