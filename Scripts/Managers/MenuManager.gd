extends Node

@onready var MenuUIScene := preload("res://Scenes/UI/MenuUI.tscn")

var menu_ui: MenuUI = null
var menu_open: bool = false

func show_menu():
	set_menu_open(true)

func hide_menu():
	set_menu_open(false)

func toggle_menu():
	set_menu_open(!menu_open)

func set_menu_open(state: bool):
	if menu_open == state:
		return

	menu_open = state

	if menu_open:
		ensure_menu_ui()
		menu_ui.show_ui()
	else:
		if menu_ui:
			menu_ui.hide_ui()

	get_tree().paused = menu_open
	InventoryManager.hide_inventory_ui()

func ensure_menu_ui():
	if menu_ui == null:
		menu_ui = MenuUIScene.instantiate()
		get_tree().get_root().add_child(menu_ui)
		menu_ui.tree_exited.connect(func(): menu_ui = null)
