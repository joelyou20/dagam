extends Control
signal selected(index: int)
signal dismissed
const Card = preload("res://Scripts/Hex/HexCardUI.gd")
var host: Control
var entries: Array = []
var grid: GridContainer
var footer: HFlowContainer
var cards: Array = []
var choices: Array = []

func configure(controller: Control, title: String, options: Array) -> void:
	host = controller
	entries = options
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 45
	var shade := ColorRect.new()

	shade.color = Color(0.015, 0.025, 0.04, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var margin := MarginContainer.new()

	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)

	add_child(margin)
	var layout := VBoxContainer.new()

	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	var heading := Label.new()

	heading.text = title
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", 22)
	layout.add_child(heading)
	var scroll := ScrollContainer.new()

	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	grid = GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	footer = HFlowContainer.new()
	footer.add_theme_constant_override("separation", 14)
	layout.add_child(footer)

	for option in entries:
		if option.get("card") == null:
			var action := Button.new()

			action.text = option.label
			action.pressed.connect(func(): selected.emit(option.index))
			footer.add_child(action)
			choices.append(action)
			continue

		var column := VBoxContainer.new()
		var owner := Label.new()
		var card: Dictionary = option.card

		column.add_theme_constant_override("separation", 4)
		grid.add_child(column)
		owner.text = "YOUR CARD" if card.get("owner", 0) == 0 else "ENEMY'S CARD"
		owner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		owner.add_theme_font_size_override("font_size", 12)
		owner.add_theme_color_override(
			"font_color", Color("9ac8ff") if card.get("owner", 0) == 0 else Color("f1a0ac")
		)
		column.add_child(owner)
		var image := Card.new()

		column.add_child(image)
		image.configure(
			{"id": card.id, "uid": card.get("uid", ""), "owner": card.get("owner", 0)},
			{"zone": "picker"},
			Vector2(128, 192)
		)
		image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		image.tooltip_text = option.label
		image.accessibility_name = option.label

		for style in ["normal", "hover", "pressed", "focus"]:
			image.add_theme_stylebox_override(style, StyleBoxEmpty.new())

		image.picked.connect(func(_card): selected.emit(option.index))
		image.inspect.connect(
			func(_value):
				var inspected: Dictionary = card.duplicate()

				inspected["picker_point"] = (
					image.get_global_rect().get_center() - host.global_position
				)
				host._inspect(inspected)
		)
		image.mouse_exited.connect(func(): host.inspection.hide())
		cards.append(image)
		choices.append(image)

	if grid.get_child_count() == 0 and entries.is_empty():
		var empty := Label.new()

		empty.text = "No cards here."
		grid.add_child(empty)

	var close := Button.new()

	close.text = "Return to board"
	close.pressed.connect(func(): dismissed.emit())
	footer.add_child(close)
	choices.append(close)
	resized.connect(_resize_cards)
	_resize_cards.call_deferred()

	if not choices.is_empty():
		choices[0].grab_focus.call_deferred()

func _resize_cards() -> void:
	var height := clampf(size.y * 0.27, 144, 192)
	var width := height * 2.0 / 3.0

	grid.columns = maxi(1, int((size.x - 64) / (width + 14)))

	for card in cards:
		card.custom_minimum_size = Vector2(width, height)

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed:
		return

	if event.keycode == KEY_TAB:
		var current := choices.find(get_viewport().gui_get_focus_owner())
		var direction := -1 if event.shift_pressed else 1

		choices[posmod(current + direction, choices.size())].grab_focus()
		get_viewport().set_input_as_handled()
