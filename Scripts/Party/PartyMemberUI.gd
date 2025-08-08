extends UIBase
class_name PartyMemberUI

var selected_party_member: AllyResource

func open_for_member(member: AllyResource):
	selected_character = member
	SceneManager.transition_to_scene("res://Scenes/CharacterMenu.tscn")
