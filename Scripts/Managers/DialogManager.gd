extends Node

var dialog_box: Control

func _ready():
	dialog_box = get_node("/root/World/DialogBox") # or use $DialogBox if it's a child

func show_dialog(lines: Array):
	if dialog_box:
		dialog_box.call("show_dialog", lines)

func is_showing_dialog() -> bool:
	return dialog_box.visible
