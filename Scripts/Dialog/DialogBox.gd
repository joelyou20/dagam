extends Control

@onready var dialog_text: Label = $DialogContainer/DialogText
@onready var name_text: Label = $NameContainer/NameText
@onready var options_container: VBoxContainer = $DialogOptionsBox/DialogOptionsContainer
@onready var dialog_options_box: Panel = $DialogOptionsBox

signal dialog_started
signal dialog_finished
signal option_selected(npc_id: String, option: DialogOption)

var dialog_lines: Array = []
var current_index := 0
var char_index := 0
var is_typing := false
var typewriter_timer := Timer.new()
var current_text: String = ""

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

func show_dialog(npc_id: String, lines: Array, dialog_name: String = "", options: Array[DialogOption] = []):
	if lines.size() == 0:
		return
	
	start_dialog()
	visible = true
	current_index = 0
	dialog_lines = lines
	_set_name(dialog_name)
	_start_typing(dialog_lines[current_index])
	_setup_options(npc_id, options)
	dialog_options_box.visible = false

func start_dialog():
		InteractionHandler.block("dialog")
		emit_signal("dialog_started")

func end_dialog():
	InteractionHandler.unblock("dialog")
	emit_signal("dialog_finished")
	
func _set_name(name: String):
	name_text.text = name

func _setup_options(npc_id: String, options: Array[DialogOption]) -> void:
	options_container.theme = null  # Prevent inherited styling from interfering

	# Remove any existing option buttons
	for child in options_container.get_children():
		child.queue_free()

	for i in options.size():
		var button := Button.new()
		button.text = options[i].text
		button.focus_mode = Control.FOCUS_NONE
		button.flat = true
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT

		# Theme overrides
		button.add_theme_color_override("font_color", Color.BLACK)                    # Normal
		button.add_theme_color_override("font_hover_color", Color(0.0, 0.0, 0.4))     # Hover (dark blue)
		button.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.2))   # Pressed
		button.add_theme_color_override("font_focus_color", Color(0.0, 0.0, 0.4))     # Focus

		# Transparent background for all visual states
		var transparent := StyleBoxFlat.new()
		transparent.bg_color = Color(0, 0, 0, 0)  # Fully transparent
		transparent.set_border_width_all(0)

		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			button.add_theme_stylebox_override(state, transparent)

		# Connect the button
		button.connect("pressed", func(): _on_option_selected(npc_id, options[i]))

		# Add to container
		options_container.add_child(button)

func _on_option_selected(npc_id: String, option: DialogOption):
	dialog_options_box.visible = false

	# Emit the signal (in case others care)
	emit_signal("option_selected", npc_id, option)
	visible = false
	end_dialog()

func _on_typewriter_tick():
	if char_index < current_text.length():
		dialog_text.text += current_text[char_index]
		char_index += 1
	else:
		typewriter_timer.stop()
		is_typing = false

func _input(event):
	if visible and (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("Interact")):
		if dialog_options_box.visible:
			return  # Wait for player to choose

		if is_typing:
			typewriter_timer.stop()
			dialog_text.text = current_text
			is_typing = false
		else:
			current_index += 1
			if current_index < dialog_lines.size():
				_start_typing(dialog_lines[current_index])
			elif options_container.get_child_count() > 0:
				dialog_options_box.visible = true
			else:
				visible = false
				end_dialog()

func is_dialog_active() -> bool:
	return visible and (is_typing or current_index < dialog_lines.size() - 1)
