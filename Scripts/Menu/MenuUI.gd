extends UIBase
class_name MenuUI

@onready var content_panels := {
	"Party": $VBoxContainer/PanelContainer/PartyPanel,
	"Equipment": $VBoxContainer/PanelContainer/EquipmentPanel,
	"Skills": $VBoxContainer/PanelContainer/SkillsPanel,
	"Inventory": $VBoxContainer/PanelContainer/InventoryPanel,
	"Formation": $VBoxContainer/PanelContainer/FormationPanel,
	"Options": $VBoxContainer/PanelContainer/OptionsPanel,
	"PartyMember": $VBoxContainer/PanelContainer/PartyMemberPanel,
}

func _ready():
	$VBoxContainer/MenuTopNav/HBoxContainer/PartyButton.pressed.connect(func(): show_panel(MenuTabs.Tab.PARTY))
	$VBoxContainer/MenuTopNav/HBoxContainer/EquipmentButton.pressed.connect(func(): show_panel(MenuTabs.Tab.EQUIPMENT))
	$VBoxContainer/MenuTopNav/HBoxContainer/SkillsButton.pressed.connect(func(): show_panel(MenuTabs.Tab.SKILLS))
	$VBoxContainer/MenuTopNav/HBoxContainer/InventoryButton.pressed.connect(func(): show_panel(MenuTabs.Tab.INVENTORY))
	$VBoxContainer/MenuTopNav/HBoxContainer/FormationButton.pressed.connect(func(): show_panel(MenuTabs.Tab.FORMATION))
	$VBoxContainer/MenuTopNav/HBoxContainer/OptionsButton.pressed.connect(func(): show_panel(MenuTabs.Tab.OPTIONS))

func show_panel(tab: MenuTabs.Tab):
	var tab_string = EnumHelper.get_name_as_string(MenuTabs.Tab, tab)
	
	for panel_name: String in content_panels.keys():
		var panel = content_panels[panel_name]
		panel.visible = (panel_name.to_lower() == tab_string.to_lower())

	if tab == MenuTabs.Tab.INVENTORY:
		if content_panels["Inventory"].has_method("update_slots"):
			content_panels["Inventory"].update_slots()
	if tab == MenuTabs.Tab.EQUIPMENT:
		if content_panels["Equipment"].has_method("update_ui"):
			content_panels["Equipment"].update_ui()
	if tab == MenuTabs.Tab.PARTY:
		if content_panels["Party"].has_method("update_party_display"):
			content_panels["Party"].update_party_display()
	if tab == MenuTabs.Tab.PARTYMEMBER:
		if content_panels["PartyMember"].has_method("update_party_member_display"):
			content_panels["PartyMember"].update_party_member_display()
		
	show_ui()
