extends Panel
class_name PartyMemberUI

var selected_party_member: AllyResource

func update_party_member_display(index: int):
	if not index:
		return
	
	selected_party_member = PartyManager.get_party()[index - 1]
	
	var character_name_label = $CharacterNameLabel
	
	character_name_label.text = selected_party_member.name
