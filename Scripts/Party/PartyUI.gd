extends Control
class_name PartyUI

@onready var member_slots := [
	$HBoxContainer/PartyMember1,
	$HBoxContainer/PartyMember2,
	$HBoxContainer/PartyMember3,
	$HBoxContainer/PartyMember4
]

func update_party_display():
	var party_members = PartyManager.get_party()
	for i in range(member_slots.size()):
		var slot_node = member_slots[i]

		# Reverse index lookup
		var reversed_index = party_members.size() - 1 - i

		if reversed_index >= 0 and reversed_index < party_members.size():
			var member = party_members[reversed_index]

			# Set sprite
			var sprite_node: Sprite2D = slot_node.get_node("Sprite2D")
			sprite_node.texture = member.portrait_texture if member.portrait_texture else null

			# Set name
			var label_node: Label = slot_node.get_node("GridContainer/Label")
			label_node.text = member.name
		else:
			# Clear slot if no member
			slot_node.get_node("Sprite2D").texture = null
			slot_node.get_node("GridContainer/Label").text = ""
