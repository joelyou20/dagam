extends UIBase
class_name PartyMemberMenuUI

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
	
	update_stats()

func update_stats(stats: Dictionary = {}):
	var speed_value_label = $Panel/StatsContainer/SpeedContainer/SpeedValueLabel
	var phys_atk_value_label = $Panel/StatsContainer/PhysAtkContainer/PhysAtkValueLabel
	var phys_def_value_label = $Panel/StatsContainer/PhysDefContainer/PhysDefValueLabel
	var mag_atk_value_label = $Panel/StatsContainer/MagAtkContainer/MagAtkValueLabel
	var mag_def_value_label = $Panel/StatsContainer/MagDefContainer/MagDefValueLabel
	
	var stats_temp = stats if !stats.is_empty() else EquipmentManager.get_equip_stats(selected_party_member)
	
	speed_value_label.text = str(stats_temp[StatOptions.Keys.SPEED])
	phys_atk_value_label.text = str(stats_temp[StatOptions.Keys.PHYS_ATK])
	phys_def_value_label.text = str(stats_temp[StatOptions.Keys.PHYS_DEF])
	mag_atk_value_label.text = str(stats_temp[StatOptions.Keys.MAG_ATK])
	mag_def_value_label.text = str(stats_temp[StatOptions.Keys.MAG_DEF])
