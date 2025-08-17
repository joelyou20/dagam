extends UIBase
class_name PartyMenuUI

@onready var member_slots := [
	$HBoxContainer/PartyMember1,
	$HBoxContainer/PartyMember2,
	$HBoxContainer/PartyMember3,
	$HBoxContainer/PartyMember4
]

func _ready():
	for i in range(member_slots.size()):
		var btn := member_slots[i] as BaseButton
		if btn:
			_make_children_ignore_mouse(btn)
			btn.pressed.connect(func(): _on_member_slot_pressed(i))

func _make_children_ignore_mouse(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_make_children_ignore_mouse(child)

func _on_member_slot_pressed(index: int):
	var party := PartyManager.get_party(true)
	if party.is_empty():
		return
	# If your display is reversed, map UI index to party index
	var reversed_index := party.size() - 1 - index
	if reversed_index < 0 or reversed_index >= party.size():
		return

	MenuManager.set_current_party_member_menu_index(reversed_index)
	MenuManager.open_nested(MenuTabs.Tab.PARTYMEMBER, self, reversed_index)

func update_party_display():
	var party_members = PartyManager.get_party()
	for i in range(member_slots.size()):
		var slot_node = member_slots[i]

		# Reverse index lookup
		var reversed_index = party_members.size() - 1 - i

		if reversed_index >= 0 and reversed_index < party_members.size():
			var member = party_members[reversed_index]

			# Set sprite
			var sprite_node: Sprite2D = slot_node.get_node("Panel/Sprite2D")
			sprite_node.texture = member.portrait_texture if member.portrait_texture else null

			# Set name
			var name_label: Label = slot_node.get_node("Panel/GridContainer/NameLabel")
			name_label.text = "Name: " + member.name
			
			# Set name
			var xp_label: Label = slot_node.get_node("Panel/GridContainer/ExperienceLabel")
			xp_label.text = "Experience: " + str(member.experience) + "/" + str(member.xp_to_next_level)
			
			# Set name
			var level_label: Label = slot_node.get_node("Panel/GridContainer/LevelLabel")
			level_label.text = "Level: " + str(member.level)
			
			# Set name
			var health_label: Label = slot_node.get_node("Panel/GridContainer/HealthLabel")
			health_label.text = "Health: " + str(member.current_hp) + "/" + str(member.max_hp)
		else:
			## Clear slot if no member
			slot_node.get_node("Panel/Sprite2D").texture = null
			slot_node.get_node("Panel/GridContainer/NameLabel").text = ""
			slot_node.get_node("Panel/GridContainer/ExperienceLabel").text = ""
			slot_node.get_node("Panel/GridContainer/LevelLabel").text = ""
			slot_node.get_node("Panel/GridContainer/HealthLabel").text = ""
