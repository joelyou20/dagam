extends UIBase
## Exploration pages read existing game state; only explicit buttons mutate it.
@export_enum("Adventure", "Journal", "Inventory") var page_kind := "Adventure"

var content: VBoxContainer
var feedback: Label

func _ready() -> void:
	super._ready()
	var panel = $Panel

	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var background = ColorRect.new()

	background.color = Color("101e27")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(background)
	var margin = MarginContainer.new()

	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)

	panel.add_child(margin)
	var scroll = ScrollContainer.new()

	margin.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)

func show_ui() -> void:
	refresh()
	super.show_ui()

func refresh() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

	_heading(page_kind.to_upper(), 30)

	match page_kind:
		"Adventure":
			_adventure()
		"Journal":
			_journal()
		"Inventory":
			_inventory()

func _heading(text: String, font_size := 21) -> Label:
	var label = Label.new()

	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("efd9a5"))
	content.add_child(label)

	return label

func _text(text: String) -> Label:
	var label = Label.new()

	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(label)

	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button = Button.new()

	button.text = text
	button.custom_minimum_size.y = 40
	parent.add_child(button)
	button.pressed.connect(callback)

	return button

func _open(tab: MenuTabs.Tab) -> void:
	MenuManager.menu_ui.open_root(tab)

func _adventure() -> void:
	HexManager.initialize()
	var player = PlayerManager.player

	_heading("%s  ·  Duelist level %d" % [player.name, player.level])
	var progress = ProgressBar.new()

	progress.max_value = player.xp_to_next_level
	progress.value = player.experience
	progress.custom_minimum_size.y = 24
	content.add_child(progress)
	_text("%d / %d XP toward your next level" % [player.experience, player.xp_to_next_level])
	_heading("Your battle deck")
	_text("%s  ·  %d / 20 cards" % [HexManager.active_deck_name, HexManager.active_deck.size()])
	_text(
		(
			"%d saved decks  ·  %d cards available to build with"
			% [HexManager.decks.size(), HexManager.session.catalog.cards.size()]
		)
	)
	var actions = HBoxContainer.new()

	content.add_child(actions)
	_button(actions, "Edit decks", func(): _open(MenuTabs.Tab.HEX))
	_button(actions, "Quest journal", func(): _open(MenuTabs.Tab.JOURNAL))
	_button(actions, "Inventory", func(): _open(MenuTabs.Tab.INVENTORY))
	_heading("On your journey")
	var completed = QuestManager.completed_quests.size()
	var active = (
		QuestManager
		. active_quests
		. keys()
		. filter(func(id): return not id in QuestManager.completed_quests)
		. size()
	)

	_text(
		(
			"%d active quests  ·  %d completed  ·  %d recruited companions"
			% [active, completed, CompanionManager.members.size()]
		)
	)
	_text(
		(
			"Challenge enemies with your selected deck. "
			+ "Companions are part of your story; duels use your cards."
		)
	)

func _journal() -> void:
	var active_count = 0

	_heading("Active quests")

	for id in QuestManager.active_quests:
		if id in QuestManager.completed_quests:
			continue

		var quest: QuestResource = QuestManager.active_quests[id]

		_heading(quest.title, 18)
		_text(quest.description)
		active_count += 1

	if active_count == 0:
		_text("No active quests. Speak to people on your journey to discover more.")

	_heading("Completed quests")

	for id in QuestManager.completed_quests:
		_text(str(id).replace("_", " ").capitalize())

	if QuestManager.completed_quests.is_empty():
		_text("Your completed quests will appear here.")

	_heading("Companions")

	for member in CompanionManager.members:
		_heading(member.get("name", member.id), 18)
		_text(member.get("description", "A companion on your journey."))

	if CompanionManager.members.is_empty():
		_text("No companions recruited yet.")

func _inventory() -> void:
	var items = InventoryManager.get_items()

	_text("%d occupied slots  ·  Supplies, quest items and keepsakes" % items.size())

	if items.is_empty():
		_text("Your bag is empty. Items found on your journey will appear here.")

	for slot in items:
		var row = HBoxContainer.new()

		row.add_theme_constant_override("separation", 16)
		content.add_child(row)
		var icon = TextureRect.new()

		icon.texture = slot.item.icon
		icon.custom_minimum_size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var label = Label.new()

		label.text = "%s × %d\n%s" % [slot.item.name, slot.quantity, slot.item.description]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		if slot.item is ConsumableResource:
			_button(row, "Use", func(): _use_item(slot.item))
		elif slot.item is EquipmentResource:
			var keepsake = Label.new()

			keepsake.text = "Keepsake"
			row.add_child(keepsake)

	feedback = _text("")

func _use_item(item: ItemResource) -> void:
	var used = InventoryManager.use_item(item)

	refresh()
	feedback.text = "Used " + item.name + "." if used else "That item has no effect right now."
