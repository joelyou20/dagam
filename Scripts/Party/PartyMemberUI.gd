extends Panel
class_name PartyMemberUI

var selected_party_member: AllyResource

func update_party_member_display():
	var index = MenuManager.current_party_member_menu_index
	if index == null:
		return
	
	var party = PartyManager.get_party()
	
	if index > party.size():
		return
	
	selected_party_member = party[index - 1]
	
	var portrait_texture_rect = $PortraitTextureRect
	var character_name_label = $CharacterNameLabel
	var level_value_label = $LevelValueLabel
	var exp_value_label = $ExpValueLabel
	var hp_value_label = $HpValueLabel
	var description_value_label = $Panel/DescriptionValueLabel
	
	portrait_texture_rect.texture = selected_party_member.portrait_texture
	character_name_label.text = selected_party_member.name
	level_value_label.text = str(selected_party_member.level)
	exp_value_label.text = str(selected_party_member.experience) + "/" + str(selected_party_member.xp_to_next_level)
	hp_value_label.text = str(selected_party_member.current_hp) + "/" + str(selected_party_member.max_hp)
	description_value_label.text = selected_party_member.description

	var speed_value_label = $Panel/StatsContainer/SpeedContainer/SpeedValueLabel
	var phys_atk_value_label = $Panel/StatsContainer/PhysAtkContainer/PhysAtkValueLabel
	var phys_def_value_label = $Panel/StatsContainer/PhysDefContainer/PhysDefValueLabel
	var mag_atk_value_label = $Panel/StatsContainer/MagAtkContainer/MagAtkValueLabel
	var mag_def_value_label = $Panel/StatsContainer/MagDefContainer/MagDefValueLabel
	
	speed_value_label.text = str(selected_party_member.speed)
	phys_atk_value_label.text = str(selected_party_member.physical_attack)
	phys_def_value_label.text = str(selected_party_member.physical_defense)
	mag_atk_value_label.text = str(selected_party_member.magical_attack)
	mag_def_value_label.text = str(selected_party_member.magical_defense)
