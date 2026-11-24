extends UIBase
## The Hex menu edits future battle decks; it never creates a match.
const Card = preload("res://Scripts/Hex/HexCardUI.gd")
const PAGE_SIZE := 12
var deck_id := "starter"
var draft: Array = []
var definitions: Dictionary = {}
var selector: OptionButton
var title: LineEdit
var search: LineEdit
var set_filter: OptionButton
var kind_filter: OptionButton
var type_filter: OptionButton
var rarity_filter: OptionButton
var deck_list: VBoxContainer
var grid: GridContainer
var metrics: Label
var status: Label
var active_label: Label
var page_label: Label
var use_button: Button
var preview: TextureRect
var page := 0
var previous_scale := -1

func _ready():
	super._ready()
	_build()

func show_ui():
	if not HexManager.initialize():
		return

	if previous_scale < 0:
		previous_scale = get_window().content_scale_mode
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS

	definitions.clear()

	for card in HexManager.session.catalog.cards:
		definitions[card.id] = card

	var index = HexManager.decks.find_custom(func(d): return d.id == deck_id)

	_select(maxi(0, index))
	_populate_filters()
	_refresh()
	super.show_ui()

func hide_ui():
	if previous_scale >= 0:
		get_window().content_scale_mode = previous_scale
		previous_scale = -1

	preview.hide()
	super.hide_ui()

func _button(parent: Node, label: String, callback: Callable):
	var b = Button.new()

	b.text = label
	b.custom_minimum_size.y = 32
	parent.add_child(b)
	b.pressed.connect(callback)

	return b

func _clear(parent: Node):
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _build():
	var panel = $Panel

	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var theme = Theme.new()

	theme.default_font_size = 16
	var style = StyleBoxFlat.new()

	style.bg_color = Color("1c3035")
	style.border_color = Color("819c93")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	theme.set_stylebox("normal", "Button", style)
	var hover = style.duplicate()

	hover.bg_color = Color("36554d")
	theme.set_stylebox("hover", "Button", hover)
	panel.theme = theme
	var background = ColorRect.new()

	background.color = Color("101c25")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(background)
	var margin = MarginContainer.new()

	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 12)

	panel.add_child(margin)
	var layout = VBoxContainer.new()

	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)
	var header = HBoxContainer.new()

	layout.add_child(header)
	var heading = Label.new()

	heading.text = "HEX  /  DECK BUILDER"
	heading.add_theme_font_size_override("font_size", 25)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	selector = OptionButton.new()
	selector.custom_minimum_size.x = 190
	selector.item_selected.connect(_choose_deck)
	header.add_child(selector)
	_button(header, "New deck", _new)
	_button(header, "Duplicate", _duplicate)
	_button(header, "Delete", _delete)
	var deck_section = HBoxContainer.new()

	deck_section.custom_minimum_size.y = 120
	layout.add_child(deck_section)
	var deck_box = VBoxContainer.new()

	deck_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_section.add_child(deck_box)
	var name_row = HBoxContainer.new()

	deck_box.add_child(name_row)
	title = LineEdit.new()
	title.placeholder_text = "Deck name"
	title.max_length = 48
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(title)
	_button(name_row, "Save deck", _save)
	use_button = _button(name_row, "Use for battles", _use)
	var scroll = ScrollContainer.new()

	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 80
	deck_box.add_child(scroll)
	deck_list = VBoxContainer.new()
	deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(deck_list)
	var details = VBoxContainer.new()

	details.custom_minimum_size.x = 250
	deck_section.add_child(details)
	metrics = Label.new()
	details.add_child(metrics)
	active_label = Label.new()
	active_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	active_label.custom_minimum_size.x = 250
	details.add_child(active_label)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = 250
	details.add_child(status)
	var filters = HBoxContainer.new()

	layout.add_child(filters)
	search = LineEdit.new()
	search.placeholder_text = "Search cards or abilities…"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.text_changed.connect(
		func(_value):
			page = 0
			_collection()
	)
	filters.add_child(search)
	set_filter = OptionButton.new()
	kind_filter = OptionButton.new()
	type_filter = OptionButton.new()
	rarity_filter = OptionButton.new()

	for filter in [set_filter, kind_filter, type_filter, rarity_filter]:
		filters.add_child(filter)
		filter.item_selected.connect(
			func(_index):
				page = 0
				_collection()
		)

	var cards_scroll = ScrollContainer.new()

	cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(cards_scroll)
	grid = GridContainer.new()
	grid.columns = 6
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	cards_scroll.add_child(grid)
	var pager = HBoxContainer.new()

	layout.add_child(pager)
	_button(
		pager,
		"Previous",
		func():
			page = maxi(0, page - 1)
			_collection()
	)
	page_label = Label.new()
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pager.add_child(page_label)
	_button(
		pager,
		"Next",
		func():
			page += 1
			_collection()
	)
	preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.z_index = 20
	preview.hide()
	panel.add_child(preview)

func _populate_filters():
	if set_filter.item_count > 0:
		return

	var sets = []
	var kinds = []
	var types = []
	var rarities = []
	var split = RegEx.new()

	split.compile("\\s+[—–-]\\s+")

	for c in definitions.values():
		if not c.set in sets:
			sets.append(c.set)

		if not c.card_type in kinds:
			kinds.append(c.card_type)

		if not c.rarity in rarities:
			rarities.append(c.rarity)

		if c.card_type == "Creature":
			var parts = c.get("types", split.sub(c.subtype, "|", true).split("|"))

			for part in parts:
				if not part in types:
					types.append(part)

	for entry in [
		[set_filter, "All sets", sets],
		[kind_filter, "All cards", kinds],
		[type_filter, "All creature types", types],
		[rarity_filter, "All rarities", rarities]
	]:
		entry[0].add_item(entry[1])
		entry[0].set_item_metadata(0, "")
		entry[2].sort()

		for value in entry[2]:
			entry[0].add_item(str(value).replace("-", " ").capitalize())
			entry[0].set_item_metadata(entry[0].item_count - 1, value)

func _select(index: int):
	if HexManager.decks.is_empty():
		_new()

		return

	index = clampi(index, 0, HexManager.decks.size() - 1)
	var item = HexManager.decks[index]

	deck_id = item.id
	draft = item.cards.duplicate()
	title.text = item.name
	status.text = ""
	_refresh()

func _new():
	deck_id = ""
	draft = []
	title.text = "New deck"
	status.text = ""
	_refresh()

func _duplicate():
	deck_id = ""
	title.text = title.text.left(40) + " copy"
	draft = draft.duplicate()
	status.text = ""
	_refresh()

func _delete():
	if deck_id.is_empty():
		_new()

		return

	if HexManager.delete_deck(deck_id):
		_select(0)
	else:
		status.text = "Unable to delete this deck."

func _save() -> bool:
	var id = HexManager.save_deck(deck_id, title.text, draft)

	if id.is_empty():
		status.text = "Unable to save this deck."

		return false

	deck_id = id
	status.text = "Saved."
	_refresh()

	return true

func _use():
	if not HexManager.deck_errors(draft).is_empty():
		return

	if not _save():
		return

	if not deck_id.is_empty() and HexManager.use_deck(deck_id):
		status.text = "Selected for new battles."
		_refresh()

func _change(id: String, amount: int):
	if amount < 0:
		var index = draft.find(id)

		if index >= 0:
			draft.remove_at(index)
	elif draft.size() < 20 and draft.count(id) < int(definitions[id].get("deckLimit", 2)):
		draft.append(id)

	var saved_id = HexManager.save_deck(deck_id, title.text, draft)

	if not saved_id.is_empty():
		deck_id = saved_id

	status.text = "Draft saved." if not saved_id.is_empty() else "Unable to save changes."
	_refresh()

func _refresh():
	if definitions.is_empty():
		return

	selector.clear()

	if deck_id.is_empty():
		selector.add_item("New deck")
		selector.set_item_metadata(0, "")

	for i in range(HexManager.decks.size()):
		selector.add_item(HexManager.decks[i].name)
		selector.set_item_metadata(selector.item_count - 1, HexManager.decks[i].id)

		if HexManager.decks[i].id == deck_id:
			selector.select(selector.item_count - 1)

	_clear(deck_list)
	var ids = []

	for id in draft:
		if not id in ids:
			ids.append(id)

	ids.sort_custom(func(a, b): return definitions[a].name < definitions[b].name)
	var kinds = {}
	var attack = 0
	var hp = 0
	var creatures = 0

	for id in draft:
		var c = definitions[id]

		kinds[c.card_type] = kinds.get(c.card_type, 0) + 1

		if c.card_type == "Creature":
			creatures += 1
			attack += int(c.attack)
			hp += int(c.hp)

	for id in ids:
		var row = HBoxContainer.new()

		deck_list.add_child(row)
		var label = _button(
			row, "%d × %s" % [draft.count(id), definitions[id].name], func(): _hover(id)
		)

		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.mouse_entered.connect(func(): _hover(id))
		label.mouse_exited.connect(preview.hide)
		var plus = _button(row, "+", func(): _change(id, 1))

		plus.disabled = (
			draft.size() >= 20 or draft.count(id) >= int(definitions[id].get("deckLimit", 2))
		)
		_button(row, "−", func(): _change(id, -1))

	metrics.text = (
		(
			"%d / 20 CARDS\n%d Creatures · %d Spells\n"
			+ "%d Items · %d Battlefields\nCreature avg: %.1f ATK / %.1f HP"
		)
		% [
			draft.size(),
			kinds.get("Creature", 0),
			kinds.get("Spell", 0),
			kinds.get("Item", 0),
			kinds.get("Battlefield", 0),
			float(attack) / maxi(1, creatures),
			float(hp) / maxi(1, creatures)
		]
	)
	active_label.text = "Battle deck: " + HexManager.active_deck_name
	use_button.disabled = not HexManager.deck_errors(draft).is_empty()
	_collection()

func _collection():
	if definitions.is_empty():
		return

	_clear(grid)
	preview.hide()
	var result = []
	var query = search.text.strip_edges().to_lower()

	for c in definitions.values():
		if not query.is_empty() and not _search_text(c).contains(query):
			continue

		if set_filter.item_count > 0 and not _matches(set_filter, c.set):
			continue

		if kind_filter.item_count > 0 and not _matches(kind_filter, c.card_type):
			continue

		if rarity_filter.item_count > 0 and not _matches(rarity_filter, c.rarity):
			continue

		if type_filter.item_count > 0 and not str(type_filter.get_selected_metadata()).is_empty():
			if not c.get("types", c.subtype.split(" — ")).has(type_filter.get_selected_metadata()):
				continue

		result.append(c)

	result.sort_custom(func(a, b): return a.name < b.name)
	page = clampi(page, 0, maxi(0, ceili(float(result.size()) / PAGE_SIZE) - 1))
	page_label.text = (
		"%d cards available  ·  Page %d / %d"
		% [result.size(), page + 1, maxi(1, ceili(float(result.size()) / PAGE_SIZE))]
	)

	for c in result.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE):
		var column = VBoxContainer.new()

		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(column)
		var card = Card.new()

		column.add_child(card)
		card.configure(
			{"id": c.id, "uid": c.id, "owner": 0}, {"zone": "collection"}, Vector2(110, 165)
		)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card.inspect.connect(func(_card): _hover(c.id))
		card.picked.connect(func(_card): _change(c.id, 1))
		card.mouse_exited.connect(preview.hide)
		var add = _button(
			column,
			"Add  ·  %d / %d" % [draft.count(c.id), int(c.get("deckLimit", 2))],
			func(): _change(c.id, 1)
		)

		add.disabled = draft.size() >= 20 or draft.count(c.id) >= int(c.get("deckLimit", 2))

func _matches(filter: OptionButton, value: String) -> bool:
	return str(filter.get_selected_metadata()).is_empty() or filter.get_selected_metadata() == value

func _hover(id: String):
	var bounds = $Panel.size
	var height = minf(560, bounds.y - 24)

	preview.texture = Card.art(id)
	preview.size = Vector2(height * 2 / 3, height)
	var point = $Panel.get_local_mouse_position()

	preview.position = Vector2(
		clampf(
			point.x + 25 if point.x < bounds.x * 0.6 else point.x - preview.size.x - 25,
			12,
			bounds.x - preview.size.x - 12
		),
		clampf(point.y - height / 2, 12, bounds.y - height - 12)
	)
	preview.show()

func _choose_deck(index: int):
	var id = selector.get_item_metadata(index)
	var found = HexManager.decks.find_custom(func(d): return d.id == id)

	if found >= 0:
		_select(found)

func _search_text(card: Dictionary) -> String:
	var text = card.name + " " + card.rules + " " + card.subtype

	for keyword in card.get("keywords", []):
		text += " " + keyword.id

		for entry in HexManager.session.catalog.keywords:
			if entry.id == keyword.id:
				text += " " + entry.name

	return text.to_lower()
