extends CanvasLayer

@onready var load_button = $MenuPanel/VBoxContainer/LoadButton

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent):
	if visible and event.is_action_pressed("ui_cancel"):
		visible = false
		get_tree().paused = false
		get_viewport().set_input_as_handled()
