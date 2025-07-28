extends Node

@onready var menu_ui := $MenuUI
var menu_open := false

func _ready():
	DialogManager.dialog_box = $DialogBox

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_toggle_menu()

func _toggle_menu():
	menu_open = !menu_open
	menu_ui.visible = menu_open
	get_tree().paused = menu_open
