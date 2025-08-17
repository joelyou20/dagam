extends Node

const EQUIP_TYPE_TO_INDEX := {
	EquipmentType.Type.HEAD:          0,
	EquipmentType.Type.CHEST:         1,
	EquipmentType.Type.BACK:          2,
	EquipmentType.Type.FEET:          3,
	EquipmentType.Type.HANDS:         4,
	EquipmentType.Type.MAIN_WEAPON:   5,
	EquipmentType.Type.OFFHAND_WEAPON:6,
}

func get_equipment_from_inventory() -> Array[EquipmentResource]:
	var items = InventoryManager.get_items()
	var equipment: Array[EquipmentResource] = []

	for i in items:
		if i.item is EquipmentResource:
			equipment.append(i.item as EquipmentResource)

	return equipment
	
func get_equipment_holders() -> Dictionary:
	var holders_by_path: Dictionary = {} # path -> Array[AllyResource]
	for m in PartyManager.get_party():
		for e in PartyManager.get_ally_equipment(m):
			if e:
				var p : String = e.resource_path
				if not holders_by_path.has(p):
					holders_by_path[p] = []
				holders_by_path[p].append(m)
	return holders_by_path

func equip_item(ally: AllyResource, equip: EquipmentResource):
	match equip.equipment_type:
		EquipmentType.Type.HEAD:
			ally.head_equipment = equip
		EquipmentType.Type.CHEST:
			ally.chest_equipment = equip
		EquipmentType.Type.BACK:
			ally.back_equipment = equip
		EquipmentType.Type.FEET:
			ally.feet_equipment = equip
		EquipmentType.Type.HANDS:
			ally.hands_equipment = equip
		EquipmentType.Type.MAIN_WEAPON:
			ally.main_weapon_equipment = equip
		EquipmentType.Type.OFFHAND_WEAPON:
			ally.offhand_weapon_equipment = equip
			
func unequip_item(ally: AllyResource, equip: EquipmentResource) -> bool:
	if ally == null or equip == null:
		return false

	var did_unequip := false

	match equip.equipment_type:
		EquipmentType.Type.HEAD:
			if ally.head_equipment == equip:
				ally.head_equipment = null
				did_unequip = true
		EquipmentType.Type.CHEST:
			if ally.chest_equipment == equip:
				ally.chest_equipment = null
				did_unequip = true
		EquipmentType.Type.BACK:
			if ally.back_equipment == equip:
				ally.back_equipment = null
				did_unequip = true
		EquipmentType.Type.FEET:
			if ally.feet_equipment == equip:
				ally.feet_equipment = null
				did_unequip = true
		EquipmentType.Type.HANDS:
			if ally.hands_equipment == equip:
				ally.hands_equipment = null
				did_unequip = true
		EquipmentType.Type.MAIN_WEAPON:
			if ally.main_weapon_equipment == equip:
				ally.main_weapon_equipment = null
				did_unequip = true
		EquipmentType.Type.OFFHAND_WEAPON:
			if ally.offhand_weapon_equipment == equip:
				ally.offhand_weapon_equipment = null
				did_unequip = true
		_:
			did_unequip = false

	if did_unequip:
		InventoryManager.add_item(equip, 1)

	return did_unequip
	
func get_equipment_on_attack_effects(unit: Unit) -> Array[OnAttackEffectEquipmentModifier]:
	var equipment: Array[EquipmentResource] = PartyManager.get_ally_equipment(unit.resource)
	var effects: Array[OnAttackEffectEquipmentModifier] = []
	for item in equipment:
		if item && item.modifiers:
			for modifier in item.modifiers:
				if modifier is OnAttackEffectEquipmentModifier:
					effects.append(modifier)
	
	return effects

func get_equipment_on_flee_effects(unit: Unit) -> Array[OnFleeStaticModifier]:
	var equipment: Array[EquipmentResource] = PartyManager.get_ally_equipment(unit.resource)
	var effects: Array[OnFleeStaticModifier] = []
	for item in equipment:
		if item && item.modifiers:
			for modifier in item.modifiers:
				if modifier is OnFleeStaticModifier:
					effects.append(modifier)
	
	return effects

func get_equip_stats(ally: AllyResource, equipment: EquipmentResource = null) -> Dictionary:
	var stats: Dictionary = {
		StatOptions.Keys.SPEED:    ally.speed,
		StatOptions.Keys.PHYS_ATK: ally.physical_attack,
		StatOptions.Keys.PHYS_DEF: ally.physical_defense,
		StatOptions.Keys.MAG_ATK:  ally.magical_attack,
		StatOptions.Keys.MAG_DEF:  ally.magical_defense,
	}

	# Start from the ally's current equipment (array of slots in a fixed order)
	var equipment_options: Array[EquipmentResource] = PartyManager.get_ally_equipment(ally).duplicate()

	# If previewing a hovered item, replace the matching slot by type
	if equipment != null:
		if EQUIP_TYPE_TO_INDEX.has(equipment.equipment_type):
			var idx := int(EQUIP_TYPE_TO_INDEX[equipment.equipment_type])
			if idx >= 0 and idx < equipment_options.size():
				equipment_options[idx] = equipment
		else:
			push_warning("Unknown equipment type: " + str(equipment.equipment_type))

	_handle_flat_stat_change_modifier(stats, equipment_options)
	_handle_percentage_stat_change_modifier(stats, equipment_options)

	return stats
	
func _handle_flat_stat_change_modifier(stats: Dictionary, equipment_options: Array[EquipmentResource]):
	# Apply modifiers. Do flat first, then percent so percent scales final value.
	for e in equipment_options:
		if e == null:
			continue
		for m in e.modifiers:
			if m is FlatStatChangeEquipmentModifier:
				match m.stat:
					StatOptions.Keys.SPEED:    stats[StatOptions.Keys.SPEED]    += m.value
					StatOptions.Keys.PHYS_ATK: stats[StatOptions.Keys.PHYS_ATK] += m.value
					StatOptions.Keys.PHYS_DEF: stats[StatOptions.Keys.PHYS_DEF] += m.value
					StatOptions.Keys.MAG_ATK:  stats[StatOptions.Keys.MAG_ATK]  += m.value
					StatOptions.Keys.MAG_DEF:  stats[StatOptions.Keys.MAG_DEF]  += m.value
	
func _handle_percentage_stat_change_modifier(stats: Dictionary, equipment_options: Array[EquipmentResource]):
	# Percentage modifiers in a second pass
	for e in equipment_options:
		if e == null:
			continue
		for m in e.modifiers:
			if m is PercentageStatChangeEquipmentModifier:
				# Decide whether m.value is 0.10 for +10% or 10 for +10:
				var factor : float = m.value
				if m.value > 1.0:
					factor = m.value / 100.0
				var mult := 1.0 + factor

				match m.stat:
					StatOptions.Keys.SPEED:    stats[StatOptions.Keys.SPEED]    = int(round(stats[StatOptions.Keys.SPEED]    * mult))
					StatOptions.Keys.PHYS_ATK: stats[StatOptions.Keys.PHYS_ATK] = int(round(stats[StatOptions.Keys.PHYS_ATK] * mult))
					StatOptions.Keys.PHYS_DEF: stats[StatOptions.Keys.PHYS_DEF] = int(round(stats[StatOptions.Keys.PHYS_DEF] * mult))
					StatOptions.Keys.MAG_ATK:  stats[StatOptions.Keys.MAG_ATK]  = int(round(stats[StatOptions.Keys.MAG_ATK]  * mult))
					StatOptions.Keys.MAG_DEF:  stats[StatOptions.Keys.MAG_DEF]  = int(round(stats[StatOptions.Keys.MAG_DEF]  * mult))
