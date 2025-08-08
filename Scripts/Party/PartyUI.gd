extends Control
class_name PartyUI

@onready var member_slots := [
	$HBoxContainer/PartyMember1,
	$HBoxContainer/PartyMember2,
	$HBoxContainer/PartyMember3,
	$HBoxContainer/PartyMember4
]

func _ready():
	for i in range(member_slots.size()):
		member_slots[i].connect("pressed", Callable(self, "_on_member_slot_pressed").bind(i))
		
func _on_member_slot_pressed(index: int):
	var party_members = PartyManager.get_party()

	var reversed_index = party_members.size() - 1 - index
	if reversed_index < 0 or reversed_index >= party_members.size():
		return

	var selected_member = party_members[reversed_index]

	# Transition to character menu and pass selected_member
	CharacterMenuManager.open_for_member(selected_member)

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
			var name_label: Label = slot_node.get_node("GridContainer/NameLabel")
			name_label.text = "Name: " + member.name
			
			# Set name
			var xp_label: Label = slot_node.get_node("GridContainer/ExperienceLabel")
			xp_label.text = "Experience: " + str(member.experience) + "/" + str(member.xp_to_next_level)
			
			# Set name
			var level_label: Label = slot_node.get_node("GridContainer/LevelLabel")
			level_label.text = "Level: " + str(member.level)
			
			# Set name
			var health_label: Label = slot_node.get_node("GridContainer/HealthLabel")
			health_label.text = "Health: " + str(member.current_hp) + "/" + str(member.max_hp)
		else:
			# Clear slot if no member
			slot_node.get_node("Sprite2D").texture = null
			slot_node.get_node("GridContainer/NameLabel").text = ""
			slot_node.get_node("GridContainer/ExperienceLabel").text = ""
			slot_node.get_node("GridContainer/LevelLabel").text = ""
			slot_node.get_node("GridContainer/HealthLabel").text = ""
