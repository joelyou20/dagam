extends UIBase
const Card = preload("res://Scripts/Hex/HexCardUI.gd")
const PAGE_SIZE := 12
var tabs: TabBar
var filters: HBoxContainer
var set_filter: OptionButton
var print_filter: OptionButton
var search: LineEdit
var grid: GridContainer
var feedback: Label
var summary: Label
var page_label: Label
var previous_button: Button
var next_button: Button
var preview: TextureRect
var receipt: PanelContainer
var receipt_cards: HFlowContainer
var page := 0
var previous_scale := -1

func _ready() -> void:
	super._ready()
	_build()
	ShopManager.changed.connect(_refresh)

func show_ui() -> void:
	if previous_scale < 0:
		previous_scale = get_window().content_scale_mode
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS

	feedback.text = "All stock is free during testing."
	_refresh()
	super.show_ui()

func hide_ui() -> void:
	preview.hide()
	receipt.hide()

	if previous_scale >= 0:
		get_window().content_scale_mode = previous_scale
		previous_scale = -1

	super.hide_ui()

func on_cancel() -> bool:
	if receipt.visible:
		receipt.hide()
		preview.hide()

		return true

	return super.on_cancel()

func _exit_tree() -> void:
	if previous_scale >= 0:
		get_window().content_scale_mode = previous_scale

	UIManager.pop(self)
	InteractionHandler.unblock(name)

func _button(parent: Node, title: String, callback: Callable) -> Button:
	var button = Button.new()

	button.text = title
	button.custom_minimum_size.y = 38
	parent.add_child(button)
	button.pressed.connect(callback)

	return button

func _label(parent: Node, text: String, font_size := 16) -> Label:
	var label = Label.new()

	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	parent.add_child(label)

	return label

func _style(colour: Color, padding := 12) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()

	style.bg_color = colour
	style.set_corner_radius_all(8)
	style.set_content_margin_all(padding)

	return style

func _build() -> void:
	var panel = $Panel
	var theme = Theme.new()

	theme.default_font_size = 16
	theme.set_color("font_color", "Label", Color("f4ebd5"))
	theme.set_stylebox("normal", "Button", _style(Color("35544b"), 8))
	theme.set_stylebox("hover", "Button", _style(Color("4b7562"), 8))
	panel.theme = theme
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var background = ColorRect.new()

	background.color = Color("11232a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(background)
	var margin = MarginContainer.new()

	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 20)

	panel.add_child(margin)
	var layout = VBoxContainer.new()

	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var header = HBoxContainer.new()

	layout.add_child(header)
	var title = _label(header, "ELDERBERRY CARDHOUSE", 26)

	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(header, "FREE TEST STOCK", 16)
	_button(header, "Leave shop", hide_ui)
	summary = _label(layout, "")
	tabs = TabBar.new()

	for title_text in ["Boosters", "Singles", "Collection", "Foundations preview"]:
		tabs.add_tab(title_text)

	layout.add_child(tabs)
	tabs.tab_changed.connect(
		func(_index):
			page = 0
			_refresh()
	)
	filters = HBoxContainer.new()
	layout.add_child(filters)
	set_filter = OptionButton.new()
	set_filter.add_item("All sets")
	set_filter.set_item_metadata(0, "")

	for set_id in ShopManager.SETS:
		set_filter.add_item(ShopManager.SETS[set_id])
		set_filter.set_item_metadata(set_filter.item_count - 1, set_id)

	filters.add_child(set_filter)
	print_filter = OptionButton.new()

	for title_text in ["Regular", "Full art", "Illustration rare"]:
		print_filter.add_item(title_text)

	filters.add_child(print_filter)
	search = LineEdit.new()
	search.placeholder_text = "Find a card…"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters.add_child(search)
	set_filter.item_selected.connect(
		func(_index):
			page = 0
			_refresh()
	)
	print_filter.item_selected.connect(
		func(_index):
			page = 0
			_refresh()
	)
	search.text_changed.connect(
		func(_text):
			page = 0
			_refresh()
	)
	var scroll = ScrollContainer.new()

	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)
	var footer = HBoxContainer.new()

	layout.add_child(footer)
	feedback = _label(footer, "", 14)
	feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	previous_button = _button(
		footer,
		"Previous",
		func():
			page -= 1
			_refresh()
	)
	page_label = _label(footer, "")
	next_button = _button(
		footer,
		"Next",
		func():
			page += 1
			_refresh()
	)
	preview = TextureRect.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.z_index = 80
	preview.hide()
	panel.add_child(preview)
	_build_receipt(panel)
	panel.resized.connect(_resize)

func _resize() -> void:
	grid.columns = 3 if get_viewport().get_visible_rect().size.x >= 900 else 2

func _build_receipt(parent: Control) -> void:
	receipt = PanelContainer.new()
	receipt.name = "BoosterReveal"
	receipt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	receipt.add_theme_stylebox_override("panel", _style(Color(0.025, 0.055, 0.075, 0.98), 24))
	receipt.z_index = 40
	parent.add_child(receipt)
	var layout = VBoxContainer.new()

	receipt.add_child(layout)
	_label(layout, "YOUR BOOSTER", 28)
	_label(layout, "Added to your collection. Hover a card for a closer look.")
	var scroll = ScrollContainer.new()

	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	receipt_cards = HFlowContainer.new()
	receipt_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	receipt_cards.add_theme_constant_override("h_separation", 14)
	scroll.add_child(receipt_cards)
	_button(
		layout,
		"Back to shop",
		func():
			receipt.hide()
			preview.hide()
	)
	receipt.hide()

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _refresh() -> void:
	if grid == null:
		return

	_clear(grid)
	preview.hide()
	_resize()
	var total := 0

	for count in ShopManager.collection.values():
		total += int(count)

	summary.text = (
		"%d cards collected · %d different prints" % [total, ShopManager.collection.size()]
	)
	filters.visible = tabs.current_tab != 0
	print_filter.visible = tabs.current_tab in [1, 3]
	set_filter.visible = tabs.current_tab != 3
	print_filter.set_item_disabled(2, tabs.current_tab == 3)

	if tabs.current_tab == 3 and print_filter.selected == 2:
		print_filter.select(0)

	if tabs.current_tab == 3:
		summary.text = "Foundations · %d preview cards" % ShopManager.preview_definitions.size()

	if tabs.current_tab == 0:
		for set_id in ShopManager.SETS:
			_pack(set_id)

		page_label.text = "3 sets"
		previous_button.disabled = true
		next_button.disabled = true

		return

	var entries = _entries()

	page = clampi(page, 0, maxi(0, ceili(entries.size() / float(PAGE_SIZE)) - 1))

	for id in entries.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE):
		_card(id, tabs.current_tab == 2)

	if entries.is_empty():
		_label(grid, "No matching cards yet." if tabs.current_tab == 2 else "No matching cards.")

	page_label.text = "%d / %d" % [page + 1, maxi(1, ceili(entries.size() / float(PAGE_SIZE)))]
	previous_button.disabled = page == 0
	next_button.disabled = (page + 1) * PAGE_SIZE >= entries.size()

func _entries() -> Array:
	var candidates: Array = []

	if tabs.current_tab == 3:
		var suffix: String = ["", "-FA"][mini(print_filter.selected, 1)]

		for id in ShopManager.preview_definitions:
			if FileAccess.file_exists("res://Assets/Hex/cards/" + id + suffix + ".hextex"):
				candidates.append(id + suffix)
	elif tabs.current_tab == 2:
		candidates = ShopManager.collection.keys()
	else:
		var suffix: String = ["", "-FA", "-IR"][print_filter.selected]

		for id in ShopManager.definitions:
			if ShopManager.valid_print(id + suffix):
				candidates.append(id + suffix)

	var selected_set: String = set_filter.get_selected_metadata()

	return candidates.filter(
		func(id):
			var data = ShopManager.card_data(id)

			return (
				(tabs.current_tab == 3 or selected_set.is_empty() or data.set == selected_set)
				and (search.text.is_empty() or search.text.to_lower() in data.name.to_lower())
			)
	)

func _product() -> VBoxContainer:
	var panel = PanelContainer.new()

	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color("213b3c")))
	grid.add_child(panel)
	var column = VBoxContainer.new()

	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	return column

func _pack(set_id: String) -> void:
	var column = _product()

	_label(column, ShopManager.SETS[set_id], 22)
	var ids = ShopManager.definitions.keys().filter(
		func(id):
			return (
				ShopManager.definitions[id].set == set_id
				and ShopManager.definitions[id].rarity == "Rare"
			)
	)
	var hero: String = ids[0]

	_image(
		column, hero + "-FA" if ShopManager.valid_print(hero + "-FA") else hero, Vector2(150, 225)
	)
	_label(column, "5 cards · Rare or better guaranteed", 14)
	_button(column, "Open free booster", func(): _open_pack(set_id))

func _card(id: String, owned: bool) -> void:
	var column = _product()
	var data = ShopManager.card_data(id)

	_image(column, id, Vector2(130, 195))
	_label(column, data.name)

	if data.get("preview_only", false):
		_label(column, data.rarity + " · Preview only", 14)

		if data.get("generated_only", false):
			_label(column, "Created by Erupt", 14)

		return

	_label(column, "%s · Collected %d" % [data.rarity, ShopManager.quantity(id)], 14)
	_button(column, "Take free card", func(): _take(id))

	if owned:
		_button(
			column,
			"Return one",
			func():
				var result = ShopManager.return_card(id)

				feedback.text = "Returned one copy to the shop." if result.ok else result.message
		)

func _image(parent: Node, id: String, dimensions: Vector2) -> TextureRect:
	var image = TextureRect.new()

	image.texture = Card.art(id)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = dimensions
	image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(image)
	image.mouse_entered.connect(func(): _inspect(id, image))
	image.mouse_exited.connect(func(): preview.hide())

	return image

func _inspect(id: String, source: Control) -> void:
	var screen = get_viewport().get_visible_rect().size
	var height = minf(screen.y - 24, 660)

	preview.texture = Card.art(id)
	preview.size = Vector2(height * 2.0 / 3.0, height)
	var origin = source.get_global_rect()
	var x = (
		origin.end.x + 12
		if origin.get_center().x < screen.x * 0.5
		else origin.position.x - preview.size.x - 12
	)

	preview.position = Vector2(clampf(x, 12, screen.x - preview.size.x - 12), 12)
	preview.show()

func _take(id: String) -> void:
	var result = ShopManager.buy_single(id)

	feedback.text = (
		"%s added to your collection." % ShopManager.card_data(id).name
		if result.ok
		else result.message
	)

func _open_pack(set_id: String) -> void:
	var result = ShopManager.buy_booster(set_id)

	if not result.ok:
		feedback.text = result.message

		return

	_clear(receipt_cards)

	for id in result.cards:
		var column = VBoxContainer.new()

		receipt_cards.add_child(column)
		_image(column, id, Vector2(160, 240))
		_label(column, ShopManager.card_data(id).rarity)

	receipt.show()
