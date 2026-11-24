class_name MenuUI
extends UIBase

const TAB_TO_KEY := {
	MenuTabs.Tab.ADVENTURE: "Adventure",
	MenuTabs.Tab.HEX: "Hex",
	MenuTabs.Tab.INVENTORY: "Inventory",
	MenuTabs.Tab.JOURNAL: "Journal",
	MenuTabs.Tab.OPTIONS: "Options",
	# Old hotkeys and serialized tab IDs resolve to the closest current page.
	MenuTabs.Tab.PARTY: "Adventure",
	MenuTabs.Tab.PARTYMEMBER: "Journal",
	MenuTabs.Tab.EQUIPMENT: "Hex",
	MenuTabs.Tab.SKILLS: "Hex",
	MenuTabs.Tab.FORMATION: "Hex",
}

# Navigation history (keys from content_uis)
var _menu_stack: Array[String] = []

@onready var content_uis := {
	"Adventure": $VBoxContainer/UIContainer/AdventureMenuUI,
	"Hex": $VBoxContainer/UIContainer/HexDeckBuilderUI,
	"Inventory": $VBoxContainer/UIContainer/InventoryMenuUI,
	"Journal": $VBoxContainer/UIContainer/JournalMenuUI,
	"Options": $VBoxContainer/UIContainer/OptionsMenuUI,
}

func _ready():
	for entry in [
		["Adventure", MenuTabs.Tab.ADVENTURE],
		["Hex", MenuTabs.Tab.HEX],
		["Inventory", MenuTabs.Tab.INVENTORY],
		["Journal", MenuTabs.Tab.JOURNAL],
		["Options", MenuTabs.Tab.OPTIONS]
	]:
		var button = get_node("VBoxContainer/MenuTopNav/HBoxContainer/" + entry[0] + "Button")

		button.pressed.connect(func(): open_root(entry[1]))

	# Child UIs should POP, not close the whole menu
	for key: String in content_uis.keys():
		var ui: UIBase = content_uis[key]

		if ui:
			ui.ui_closed.connect(func(): _on_child_ui_closed(key))


# Public: open a top-level tab (clears stack)

func open_root(tab: MenuTabs.Tab):
	if HexManager.is_battle_open():
		return
	# Hide everything first
	for ui: UIBase in content_uis.values():
		if ui:
			ui.hide_ui()

	_menu_stack.clear()
	_show_tab(tab, true)
	show_ui()
	MenuManager.current_tab = tab


# Public: push a nested menu (e.g., Party -> PartyMember)

func show_menu(tab: MenuTabs.Tab):
	_show_tab(tab, true)
	show_ui()


# Close current menu level; if none left, close the whole MenuUI

func close_menu(tab: MenuTabs.Tab = MenuTabs.Tab.UNSET):
	if _menu_stack.is_empty():
		hide_ui()

		return

	# If a specific tab is given and it's the current, pop it; otherwise just pop current

	var current_key: String = _menu_stack.back()
	var target_key: String = TAB_TO_KEY.get(tab, current_key)

	if current_key == target_key:
		_pop_current_and_show_previous()
	else:
		# If they asked to close some other tab, just hide it (rare)
		if content_uis.has(target_key) and content_uis[target_key]:
			content_uis[target_key].hide_ui()

		if _menu_stack.is_empty():
			hide_ui()


# --- Internals ---

func _show_tab(tab: MenuTabs.Tab, push: bool):
	var key: String = TAB_TO_KEY.get(tab, "")

	if key == "" or not content_uis.has(key):
		return

	# Hide current top if we’re replacing it; otherwise stack push

	if push:
		if not _menu_stack.is_empty():
			var current: String = _menu_stack.back()

			if content_uis.has(current) and content_uis[current]:
				content_uis[current].hide_ui()

		_menu_stack.append(key)

	# Finally, show the requested UI

	content_uis[key].show_ui()

func _on_child_ui_closed(child_key: String):
	# Only act if the closing child is the top of the stack
	if not _menu_stack.is_empty() and _menu_stack.back() == child_key:
		_pop_current_and_show_previous()
		# If stack emptied, close the whole menu

		if _menu_stack.is_empty():
			hide_ui()

func _pop_current_and_show_previous():
	var current: String = _menu_stack.pop_back()

	if content_uis.has(current) and content_uis[current]:
		content_uis[current].hide_ui()

	if not _menu_stack.is_empty():
		var prev: String = _menu_stack.back()

		if content_uis.has(prev) and content_uis[prev]:
			content_uis[prev].show_ui()
	else:
		# Nothing left on stack
		hide_ui()

func on_cancel() -> bool:
	if not _menu_stack.is_empty():
		var current: UIBase = content_uis.get(_menu_stack.back())

		if current and current.has_method("consume_cancel") and current.consume_cancel():
			return true
	# If there are multiple levels, pop back to previous tab

	if _menu_stack.size() > 1:
		_pop_current_and_show_previous()

		return true

	# If there is exactly one tab open, close that tab and the menu

	if _menu_stack.size() == 1:
		var only: String = _menu_stack.pop_back()

		if content_uis.has(only) and content_uis[only]:
			content_uis[only].hide_ui()

		hide_ui()

		return true

	# No tabs tracked; close the container

	hide_ui()

	return true
