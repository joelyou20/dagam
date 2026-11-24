extends Node
## Read-only compatibility for legacy equipment resources and editor previews.
## World equipment never changes a Hex card or the player's progression.

func get_equipment_from_inventory() -> Array[EquipmentResource]:
	return []

func get_equipment_holders() -> Dictionary:
	return {}

func equip_item(_ally: AllyResource, _equipment: EquipmentResource) -> void:
	pass

func unequip_item(_ally: AllyResource, _equipment: EquipmentResource) -> bool:
	return false

func get_equipment_on_attack_effects(_unit: Unit) -> Array[OnAttackEffectEquipmentModifier]:
	return []

func get_equipment_on_flee_effects(_unit: Unit) -> Array[OnFleeStaticModifier]:
	return []

func get_equip_stats(ally: AllyResource, _equipment: EquipmentResource = null) -> Dictionary:
	return {
		StatOptions.Keys.SPEED: ally.speed,
		StatOptions.Keys.PHYS_ATK: ally.physical_attack,
		StatOptions.Keys.PHYS_DEF: ally.physical_defense,
		StatOptions.Keys.MAG_ATK: ally.magical_attack,
		StatOptions.Keys.MAG_DEF: ally.magical_defense,
	}
