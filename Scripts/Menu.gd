# MenuUI.gd
extends CanvasLayer

@onready var load_button = $MenuPanel/VBoxContainer/LoadButton

func _ready():
	# Hide menu at start
	visible = false

func _on_resume_pressed():
	visible = false

func _on_quit_pressed():
	get_tree().quit()
