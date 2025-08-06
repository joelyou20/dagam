extends UIBase
class_name MenuUI

@onready var content_panels := {
	"Party": $VBoxContainer/PanelContainer/PartyPanel,
	"Skills": $VBoxContainer/PanelContainer/SkillsPanel,
	"Inventory": $VBoxContainer/PanelContainer/InventoryPanel,
	"Formation": $VBoxContainer/PanelContainer/FormationPanel,
	"Options": $VBoxContainer/PanelContainer/OptionsPanel
}

func _ready():
	$VBoxContainer/MenuTopNav/HBoxContainer/PartyButton.pressed.connect(func(): show_panel(MenuTabs.Tab.PARTY))
	$VBoxContainer/MenuTopNav/HBoxContainer/SkillsButton.pressed.connect(func(): show_panel(MenuTabs.Tab.SKILLS))
	$VBoxContainer/MenuTopNav/HBoxContainer/InventoryButton.pressed.connect(func(): show_panel(MenuTabs.Tab.INVENTORY))
	$VBoxContainer/MenuTopNav/HBoxContainer/FormationButton.pressed.connect(func(): show_panel(MenuTabs.Tab.FORMATION))
	$VBoxContainer/MenuTopNav/HBoxContainer/OptionsButton.pressed.connect(func(): show_panel(MenuTabs.Tab.OPTIONS))

func show_panel(tab: MenuTabs.Tab):
	var tab_string = EnumHelper.get_name_as_string(MenuTabs.Tab, tab)
	
	for panel_name: String in content_panels.keys():
		var panel = content_panels[panel_name]
		panel.visible = (panel_name.to_lower() == tab_string.to_lower())

	# Special case: refresh inventory when opened
	if tab == MenuTabs.Tab.INVENTORY:
		if content_panels["Inventory"].has_method("update_slots"):
			content_panels["Inventory"].update_slots()
	if tab == MenuTabs.Tab.PARTY:
		if content_panels["Party"].has_method("update_party_display"):
			content_panels["Party"].update_party_display()

	show_ui()
