extends RefCounted
const Icon = preload("res://Scripts/Hex/HexStatusIcon.gd")
var tooltip: PanelContainer
var entries: VBoxContainer

func _init(parent: Control) -> void:
	tooltip = PanelContainer.new()
	tooltip.name = "ActiveStatuses"
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.z_index = 51
	var background = StyleBoxFlat.new()

	background.bg_color = Color(0.015, 0.025, 0.04, 0.76)
	background.set_content_margin_all(12)
	background.set_corner_radius_all(8)
	tooltip.add_theme_stylebox_override("panel", background)
	entries = VBoxContainer.new()
	entries.add_theme_constant_override("separation", 8)
	entries.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.add_child(entries)
	parent.add_child(tooltip)
	tooltip.hide()

func add_symbols(parent: Control, effects: Array, width: float) -> void:
	if effects.is_empty():
		return

	var columns = maxi(1, int(width / 22))
	var rows = ceili(float(effects.size()) / columns)

	for index in range(effects.size()):
		var icon = Icon.new()
		var count = mini(columns, effects.size() - (index / columns) * columns)

		icon.effect = effects[index]
		icon.size = Vector2(20, 20)
		icon.position = Vector2(
			(width - count * 22) * 0.5 + (index % columns) * 22, -22 * rows + (index / columns) * 22
		)
		parent.add_child(icon)

func show_effects(effects: Array, card_rect: Rect2, screen: Vector2) -> void:
	for child in entries.get_children():
		entries.remove_child(child)
		child.queue_free()

	tooltip.hide()

	if effects.is_empty():
		return

	var width = minf(235, screen.x * 0.3)
	var scroll = ScrollContainer.new()

	scroll.custom_minimum_size = Vector2(width, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entries.add_child(scroll)
	var list = VBoxContainer.new()

	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(list)
	var content_height = 0.0

	for effect in effects:
		var row = HBoxContainer.new()
		var icon = Icon.new()
		var label = Label.new()

		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.effect = effect
		icon.custom_minimum_size = Vector2(22, 22)
		label.text = (
			effect.name
			+ (" %d" % effect.amount if effect.amount != 0 else "")
			+ "\n"
			+ effect.description
		)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = width - 32
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 14)

		if effect.id == "resolving":
			label.add_theme_color_override("font_color", Color("b5eaff"))
			label.add_theme_color_override("font_shadow_color", Color(0.3, 0.75, 1.0, 0.55))
			label.add_theme_constant_override("shadow_outline_size", 4)
			label.pivot_offset = label.get_minimum_size() * 0.5
			var pulse := label.create_tween().set_loops()

			pulse.tween_property(label, "modulate:a", 0.72, 0.65)
			pulse.parallel().tween_property(label, "scale", Vector2(1.012, 1.012), 0.65)
			pulse.tween_property(label, "modulate:a", 1.0, 0.65)
			pulse.parallel().tween_property(label, "scale", Vector2.ONE, 0.65)

		row.add_child(icon)
		row.add_child(label)
		list.add_child(row)
		content_height += label.get_minimum_size().y + 10

	scroll.custom_minimum_size.y = minf(content_height, screen.y - 48)
	tooltip.reset_size()
	var x = card_rect.end.x + 10

	if x + width + 24 > screen.x:
		x = card_rect.position.x - width - 34

	tooltip.position = Vector2(
		maxf(8, x),
		clampf(card_rect.position.y, 8, maxf(8, screen.y - scroll.custom_minimum_size.y - 32))
	)
	tooltip.show()
