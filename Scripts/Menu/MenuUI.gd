extends UIBase
class_name MenuUI

@onready var content_panels := {
	"Party": $VBoxContainer/PanelContainer/PartyPanel,
	"Skills": $VBoxContainer/PanelContainer/SkillsPanel,
	"Inventory": $VBoxContainer/PanelContainer/InventoryPanel,
	"Formation": $VBoxContainer/PanelContainer/FormationPanel,
	"Options": $VBoxContainer/PanelContainer/OptionsPanel,
	"PartyMember1": $VBoxContainer/PanelContainer/PartyMemberPanel,
	"PartyMember2": $VBoxContainer/PanelContainer/PartyMemberPanel,
	"PartyMember3": $VBoxContainer/PanelContainer/PartyMemberPanel,
	"PartyMember4": $VBoxContainer/PanelContainer/PartyMemberPanel
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
	if tab == MenuTabs.Tab.PARTYMEMBER1:
		if content_panels["PartyMember1"].has_method("update_party_member_display"):
			content_panels["PartyMember1"].update_party_member_display(1)
	if tab == MenuTabs.Tab.PARTYMEMBER2:
		if content_panels["PartyMember2"].has_method("update_party_member_display"):
			content_panels["PartyMember2"].update_party_member_display(2)
	if tab == MenuTabs.Tab.PARTYMEMBER3:
		if content_panels["PartyMember3"].has_method("update_party_member_display"):
			content_panels["PartyMember3"].update_party_member_display(3)
	if tab == MenuTabs.Tab.PARTYMEMBER4:
		if content_panels["PartyMember4"].has_method("update_party_member_display"):
			content_panels["PartyMember4"].update_party_member_display(4)
		

	show_ui()
