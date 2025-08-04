extends UIBase
class_name DialogUI

@onready var dialog_box: Panel = $Panel
@onready var dialog_text: Label = $Panel/DialogContainer/DialogText
@onready var name_text: Label = $Panel/NameContainer/NameText
@onready var options_container: VBoxContainer = $Panel/DialogOptionsBox/DialogOptionsContainer
@onready var dialog_options_box: Panel = $Panel/DialogOptionsBox

@warning_ignore("unused_signal")
signal option_selected(npc_id: String, option: DialogOption)

var dialog_lines: Array = []
var current_index: int = 0
var char_index: int = 0
var is_typing: bool = false
var current_text: String = ""
var _npc_id: String = ""

var typewriter_timer: Timer = Timer.new()

func _ready():
	typewriter_timer.wait_time = 0.03
	typewriter_timer.one_shot = false
	typewriter_timer.timeout.connect(_on_typewriter_tick)
	add_child(typewriter_timer)

func show_dialog(id: String, lines: Array, dialog_name: String = "", options: Array[DialogOption] = []):
	if lines.size() == 0:
		return

	_npc_id = id
	dialog_lines = lines
	current_index = 0
	_set_name(dialog_name)
	_setup_options(_npc_id, options)
	dialog_options_box.visible = false
	show_ui()
	_start_typing(dialog_lines[current_index])

func _start_typing(text: String):
	dialog_text.text = ""
	char_index = 0
	current_text = text
	is_typing = true
	typewriter_timer.start()

func _set_name(value: String):
	name_text.text = value

func _setup_options(npc_id: String, options: Array[DialogOption]) -> void:
	options_container.theme = null  # Prevent inherited styling from interfering

	for child in options_container.get_children():
		child.queue_free()

	for option in options:
		var button := Button.new()
		button.text = option.text
		button.focus_mode = Control.FOCUS_NONE
		button.flat = true
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT

		# Theme overrides
		button.add_theme_color_override("font_color", Color.BLACK)
		button.add_theme_color_override("font_hover_color", Color(0.0, 0.0, 0.4))
		button.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.2))
		button.add_theme_color_override("font_focus_color", Color(0.0, 0.0, 0.4))

		var transparent := StyleBoxFlat.new()
		transparent.bg_color = Color(0, 0, 0, 0)
		transparent.set_border_width_all(0)

		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			button.add_theme_stylebox_override(state, transparent)

		button.pressed.connect(func(): _on_option_selected(npc_id, option))
		options_container.add_child(button)

func _on_option_selected(npc_id: String, option: DialogOption):
	dialog_options_box.visible = false
	emit_signal("option_selected", npc_id, option)
	hide_ui()

func _on_typewriter_tick():
	if char_index < current_text.length():
		dialog_text.text += current_text[char_index]
		char_index += 1
	else:
		typewriter_timer.stop()
		is_typing = false

func _input(_event):
	if visible and (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("Interact")):
		if dialog_options_box.visible:
			return

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
				hide_ui()

func is_dialog_active() -> bool:
	return visible and (is_typing or current_index < dialog_lines.size() - 1)
