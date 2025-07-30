extends Node

@onready var menu_ui := $MenuUI
@onready var dialog_box := $DialogBox

var menu_open := false

func _ready():
	DialogManager.dialog_box = dialog_box
	SceneManager._load_scene("res://Scenes/Test.tscn", "PlayerSpawn")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_set_menu_open(!menu_open)

func _set_menu_open(state: bool):
	if menu_open == state:
		return  # Already in desired state

	menu_open = state
	menu_ui.visible = menu_open
	get_tree().paused = menu_open
