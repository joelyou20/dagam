extends Control

@onready var dialog_text: Label = $DialogContainer/DialogText
var dialog_lines: Array = []
var current_index := 0
var char_index := 0
var is_typing := false
var typewriter_timer := Timer.new()
var current_text: String = '';

func _ready():
	visible = false
	typewriter_timer.wait_time = 0.03
	typewriter_timer.one_shot = false
	typewriter_timer.timeout.connect(_on_typewriter_tick)
	add_child(typewriter_timer)
	
func _start_typing(text: String):
	dialog_text.text = ""
	char_index = 0
	is_typing = true
	current_text = text
	typewriter_timer.start()


func show_dialog(lines: Array):
	visible = true
	dialog_lines = lines
	current_index = 0
	_start_typing(dialog_lines[current_index])

func _on_typewriter_tick():
	if char_index < current_text.length():
		dialog_text.text += current_text[char_index]
		char_index += 1
	else:
		typewriter_timer.stop()
		is_typing = false

func _input(event):
	if visible and (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("Interact")):
		if is_typing:
			# Skip to full line
			typewriter_timer.stop()
			dialog_text.text = current_text
			is_typing = false
		else:
			current_index += 1
			if current_index < dialog_lines.size():
				_start_typing(dialog_lines[current_index])
			else:
				visible = false

func is_dialog_active() -> bool:
	return visible and (is_typing or current_index < dialog_lines.size() - 1)
