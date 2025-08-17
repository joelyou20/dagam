extends UIBase
class_name EquipmentMenuUI

var current_party_member: AllyResource
var current_party_member_index: int = 0

func _ready():
	var next_party_member_button = $NextPartyMemberButton
	var previous_party_member_button = $PreviousPartyMemberButton

	next_party_member_button.pressed.connect(on_next_party_member_button_pressed)
	next_party_member_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	previous_party_member_button.pressed.connect(on_previous_party_member_button_pressed)
	previous_party_member_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var head_button = $Panel/EquipmentContainer/HeadButton
	var chest_button = $Panel/EquipmentContainer/ChestButton
	var back_button = $Panel/EquipmentContainer/BackButton
	var feet_button = $Panel/EquipmentContainer/FeetButton
	var hands_button = $Panel/EquipmentContainer/HandsButton
	var main_weapon_button = $Panel/EquipmentContainer/MainWeaponButton
	var offhand_weapon_button = $Panel/EquipmentContainer/OffhandWeaponButton
	
	head_button.pressed.connect(_update_equip_list.bind(EquipmentType.Type.HEAD))
	head_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	chest_button.pressed.connect(_update_equip_list.bind(EquipmentType.Type.CHEST))
	chest_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	back_button.pressed.connect(_update_equip_list.bind(EquipmentType.Type.BACK))
	back_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	feet_button.pressed.connect(_update_equip_list.bind(EquipmentType.Type.FEET))
	feet_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	hands_button.pressed.connect(_update_equip_list.bind(EquipmentType.Type.HANDS))
	hands_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	main_weapon_button.pressed.connect(_update_equip_list.bind(EquipmentType.Type.MAIN_WEAPON))
	main_weapon_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	offhand_weapon_button.pressed.connect(_update_equip_list.bind(EquipmentType.Type.OFFHAND_WEAPON))
	offhand_weapon_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
func on_next_party_member_button_pressed():
	if current_party_member_index + 1 > PartyManager.get_party().size() - 1:
		current_party_member_index = 0
	else:
		current_party_member_index += 1
	update_ui()
	
func on_previous_party_member_button_pressed():
	if current_party_member_index - 1 < 0:
		current_party_member_index = PartyManager.get_party().size() - 1
	else:
		current_party_member_index -= 1
	update_ui()

func update_ui():
	var party = PartyManager.get_party()
	current_party_member = party[current_party_member_index]
	
	_clear_equipment_list()
	
	var portrait_texture_rect = $PortraitTextureRect
	var character_name_label = $CharacterNameLabel
	var level_value_label = $LevelValueLabel
	var exp_value_label = $ExpValueLabel
	var hp_value_label = $HpValueLabel
	var description_value_label = $Panel/DescriptionValueLabel
	
	portrait_texture_rect.texture = current_party_member.portrait_texture
	character_name_label.text = current_party_member.name
	level_value_label.text = str(current_party_member.level)
	exp_value_label.text = str(current_party_member.experience) + "/" + str(current_party_member.xp_to_next_level)
	hp_value_label.text = str(current_party_member.current_hp) + "/" + str(current_party_member.max_hp)
	description_value_label.text = current_party_member.description

	update_stats()
	
	var head_label = $Panel/EquipmentContainer/HeadButton/HeadContainer/HeadLabel
	var head_texture_rect = $Panel/EquipmentContainer/HeadButton/HeadContainer/HeadTextureRect
	var chest_label = $Panel/EquipmentContainer/ChestButton/ChestContainer/ChestLabel
	var chest_texture_rect = $Panel/EquipmentContainer/ChestButton/ChestContainer/ChestTextureRect
	var back_label = $Panel/EquipmentContainer/BackButton/BackContainer/BackLabel
	var back_texture_rect = $Panel/EquipmentContainer/BackButton/BackContainer/TextureRect
	var feet_label = $Panel/EquipmentContainer/FeetButton/FeetContainer/FeetLabel
	var feet_texture_rect = $Panel/EquipmentContainer/FeetButton/FeetContainer/FeetTextureRect
	var hands_label = $Panel/EquipmentContainer/HandsButton/HandsContainer/HandsLabel
	var hands_texture_rect = $Panel/EquipmentContainer/HandsButton/HandsContainer/HandsTextureRect
	var main_weapon_label = $Panel/EquipmentContainer/MainWeaponButton/MainWeaponContainer/MainWeaponLabel
	var main_weapon_texture_rect = $Panel/EquipmentContainer/MainWeaponButton/MainWeaponContainer/MainWeaponTextureRect
	var offhand_weapon_label = $Panel/EquipmentContainer/OffhandWeaponButton/OffhandWeaponContainer/OffHandWeaponLabel
	var offhand_weapon_texture_rect = $Panel/EquipmentContainer/OffhandWeaponButton/OffhandWeaponContainer/OffhandWeaponTextureRect
	
	var default_head_texture_rect: Texture2D = preload("res://Assets/Sprites/Helmet-Icon.png")
	var default_chest_texture_rect: Texture2D = preload("res://Assets/Sprites/Chest-Icon.png")
	var default_back_texture_rect: Texture2D = preload("res://Assets/Sprites/Back-Icon.png")
	var default_feet_texture_rect: Texture2D = preload("res://Assets/Sprites/Foot-Icon.png")
	var default_hands_texture_rect: Texture2D = preload("res://Assets/Sprites/Hands-Icon.png")
	var default_main_weapon_texture_rect: Texture2D = preload("res://Assets/Sprites/MainWeapon-Icon.png")
	var default_offhand_weapon_texture_rect: Texture2D = preload("res://Assets/Sprites/OffhandWeapon-Icon.png")
	
	head_label.text = current_party_member.head_equipment.name if current_party_member.head_equipment != null else "Empty"
	head_texture_rect.texture = current_party_member.head_equipment.icon if current_party_member.head_equipment != null else default_head_texture_rect
	chest_label.text = current_party_member.chest_equipment.name if current_party_member.chest_equipment != null else "Empty"
	chest_texture_rect.texture = current_party_member.chest_equipment.icon if current_party_member.chest_equipment != null else default_chest_texture_rect
	back_label.text = current_party_member.back_equipment.name if current_party_member.back_equipment != null else "Empty"
	back_texture_rect.texture = current_party_member.back_equipment.icon if current_party_member.back_equipment != null else default_back_texture_rect
	feet_label.text = current_party_member.feet_equipment.name if current_party_member.feet_equipment != null else "Empty"
	feet_texture_rect.texture = current_party_member.feet_equipment.icon if current_party_member.feet_equipment != null else default_feet_texture_rect
	hands_label.text = current_party_member.hands_equipment.name if current_party_member.hands_equipment != null else "Empty"
	hands_texture_rect.texture = current_party_member.hands_equipment.icon if current_party_member.hands_equipment != null else default_hands_texture_rect
	main_weapon_label.text = current_party_member.main_weapon_equipment.name if current_party_member.main_weapon_equipment != null else "Empty"
	main_weapon_texture_rect.texture = current_party_member.main_weapon_equipment.icon if current_party_member.main_weapon_equipment != null else default_main_weapon_texture_rect
	offhand_weapon_label.text = current_party_member.offhand_weapon_equipment.name if current_party_member.offhand_weapon_equipment != null else "Empty"
	offhand_weapon_texture_rect.texture = current_party_member.offhand_weapon_equipment.icon if current_party_member.offhand_weapon_equipment != null else default_offhand_weapon_texture_rect
	
func _clear_equipment_list():
	var equip_replace_container: GridContainer = $Panel/EquipReplaceContainer/GridContainer
	
	for c in equip_replace_container.get_children():
		c.queue_free()

func _update_equip_list(equipment_type: EquipmentType.Type):
	var equip_replace_container: GridContainer = $Panel/EquipReplaceContainer/GridContainer
	
	_clear_equipment_list()

	# 1) Who is holding what? (by resource path)
	var equipment_dictionary = EquipmentManager.get_equipment_holders()

	# Make a working copy we can pop from
	var remaining_holders: Dictionary = {}
	for k in equipment_dictionary.keys():
		remaining_holders[k] = equipment_dictionary[k].duplicate()

	# 2) Build a flat list: one entry PER COPY in inventory
	var entries: Array = []  # each: {equip: EquipmentResource, path: String}
	var inventory = InventoryManager.get_inventory()
	for slot in inventory.slots:
		if not slot.is_empty() and slot.item is EquipmentResource:
			var e := slot.item as EquipmentResource
			if e.equipment_type == equipment_type:
				for i in range(slot.quantity):
					entries.append({"equip": e, "path": e.resource_path})

	# 3) Render rows. If a holder exists for that path, lock that one copy and show the holder.
	for entry in entries:
		var equip: EquipmentResource = entry.equip
		var path: String = entry.path
		var holder: AllyResource = null
		if remaining_holders.has(path) and remaining_holders[path].size() > 0:
			holder = remaining_holders[path].pop_front()

		_add_equipment_row(equip_replace_container, equip, holder)

func update_stats(stats: Dictionary = {}):
	var speed_value_label = $Panel/StatsContainer/SpeedContainer/SpeedValueLabel
	var phys_atk_value_label = $Panel/StatsContainer/PhysAtkContainer/PhysAtkValueLabel
	var phys_def_value_label = $Panel/StatsContainer/PhysDefContainer/PhysDefValueLabel
	var mag_atk_value_label = $Panel/StatsContainer/MagAtkContainer/MagAtkValueLabel
	var mag_def_value_label = $Panel/StatsContainer/MagDefContainer/MagDefValueLabel
	
	var stats_temp = stats if !stats.is_empty() else EquipmentManager.get_equip_stats(current_party_member)
	
	speed_value_label.text = str(stats_temp[StatOptions.Keys.SPEED])
	phys_atk_value_label.text = str(stats_temp[StatOptions.Keys.PHYS_ATK])
	phys_def_value_label.text = str(stats_temp[StatOptions.Keys.PHYS_DEF])
	mag_atk_value_label.text = str(stats_temp[StatOptions.Keys.MAG_ATK])
	mag_def_value_label.text = str(stats_temp[StatOptions.Keys.MAG_DEF])

func _add_equipment_row(container: GridContainer, equip: EquipmentResource, holder: AllyResource) -> void:
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_ALL
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 36)
	btn.text = ""
	btn.icon = null
	btn.disabled = holder != null

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Left
	var left := HBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon := TextureRect.new()
	icon.texture = equip.icon
	icon.custom_minimum_size = Vector2(32, 32)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var name_lbl := Label.new()
	name_lbl.text = equip.name
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", Color.BLACK)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	left.add_child(icon)
	left.add_child(name_lbl)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Right (holder)
	var right := HBoxContainer.new()
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if holder != null:
		var holder_icon := TextureRect.new()
		holder_icon.texture = holder.portrait_texture
		holder_icon.custom_minimum_size = Vector2(24, 24)
		holder_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		holder_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var holder_lbl := Label.new()
		holder_lbl.text = holder.name
		holder_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		holder_lbl.add_theme_color_override("font_color", Color.BLACK)
		holder_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		right.add_child(holder_icon)
		right.add_child(holder_lbl)

	row.add_child(left)
	row.add_child(spacer)
	row.add_child(right)
	btn.add_child(row)

	if not btn.disabled:
		btn.pressed.connect(_on_equip_row_pressed.bind(equip))

	# Hover in/out
	btn.mouse_entered.connect(func():
		btn.self_modulate = Color(0.9, 0.9, 0.9)  # darken
		_on_equip_row_hovered(equip)
	)
	btn.mouse_exited.connect(func():
		btn.self_modulate = Color(1, 1, 1)        # restore
		_on_equip_row_unhovered()
	)

	container.add_child(btn)


func _on_equip_row_hovered(equip: EquipmentResource):
	$Panel/DescriptionValueLabel.text = equip.description
	var before_equip_stats = EquipmentManager.get_equip_stats(current_party_member)
	var after_equip_stats = EquipmentManager.get_equip_stats(current_party_member, equip)
	
	var speed_sprite = $Panel/StatsContainer/SpeedContainer/SpeedSprite
	var phys_atk_sprite = $Panel/StatsContainer/PhysAtkContainer/PhysAtkSprite
	var phys_def_sprite = $Panel/StatsContainer/PhysDefContainer/PhysDefSprite
	var mag_atk_sprite = $Panel/StatsContainer/MagAtkContainer/MagAtkSprite
	var mag_def_sprite = $Panel/StatsContainer/MagDefContainer/MagDefSprite
	
	if after_equip_stats[StatOptions.Keys.SPEED] > before_equip_stats[StatOptions.Keys.SPEED]:
		speed_sprite.texture = preload("res://Assets/Sprites/Arrow_Up.png")
		speed_sprite.show()
	if after_equip_stats[StatOptions.Keys.SPEED] < before_equip_stats[StatOptions.Keys.SPEED]:
		speed_sprite.texture = preload("res://Assets/Sprites/Arrow_002.png")
		speed_sprite.show()
	if after_equip_stats[StatOptions.Keys.PHYS_ATK] > before_equip_stats[StatOptions.Keys.PHYS_ATK]:
		phys_atk_sprite.texture = preload("res://Assets/Sprites/Arrow_Up.png")
		phys_atk_sprite.show()
	if after_equip_stats[StatOptions.Keys.PHYS_ATK] < before_equip_stats[StatOptions.Keys.PHYS_ATK]:
		phys_atk_sprite.texture = preload("res://Assets/Sprites/Arrow_002.png")
		phys_atk_sprite.show()
	if after_equip_stats[StatOptions.Keys.PHYS_DEF] > before_equip_stats[StatOptions.Keys.PHYS_DEF]:
		phys_def_sprite.texture = preload("res://Assets/Sprites/Arrow_Up.png")
		phys_def_sprite.show()
	if after_equip_stats[StatOptions.Keys.PHYS_DEF] < before_equip_stats[StatOptions.Keys.PHYS_DEF]:
		phys_def_sprite.texture = preload("res://Assets/Sprites/Arrow_002.png")
		phys_def_sprite.show()
	if after_equip_stats[StatOptions.Keys.MAG_ATK] > before_equip_stats[StatOptions.Keys.MAG_ATK]:
		mag_atk_sprite.texture = preload("res://Assets/Sprites/Arrow_Up.png")
		mag_atk_sprite.show()
	if after_equip_stats[StatOptions.Keys.MAG_ATK] < before_equip_stats[StatOptions.Keys.MAG_ATK]:
		mag_atk_sprite.texture = preload("res://Assets/Sprites/Arrow_002.png")
		mag_atk_sprite.show()
	if after_equip_stats[StatOptions.Keys.MAG_DEF] > before_equip_stats[StatOptions.Keys.MAG_DEF]:
		mag_def_sprite.texture = preload("res://Assets/Sprites/Arrow_Up.png")
		mag_def_sprite.show()
	if after_equip_stats[StatOptions.Keys.MAG_DEF] < before_equip_stats[StatOptions.Keys.MAG_DEF]:
		mag_def_sprite.texture = preload("res://Assets/Sprites/Arrow_002.png")
		mag_def_sprite.show()
		
	update_stats(after_equip_stats)
	
func _on_equip_row_unhovered():
	$Panel/DescriptionValueLabel.text = ""
	
	var speed_sprite = $Panel/StatsContainer/SpeedContainer/SpeedSprite
	var phys_atk_sprite = $Panel/StatsContainer/PhysAtkContainer/PhysAtkSprite
	var phys_def_sprite = $Panel/StatsContainer/PhysDefContainer/PhysDefSprite
	var mag_atk_sprite = $Panel/StatsContainer/MagAtkContainer/MagAtkSprite
	var mag_def_sprite = $Panel/StatsContainer/MagDefContainer/MagDefSprite
	
	speed_sprite.hide()
	phys_atk_sprite.hide()
	phys_def_sprite.hide()
	mag_atk_sprite.hide()
	mag_def_sprite.hide()
	
	update_stats()

func _on_equip_row_pressed(equip: EquipmentResource):
	EquipmentManager.equip_item(current_party_member, equip)
	update_ui()  # refresh portrait + labels
