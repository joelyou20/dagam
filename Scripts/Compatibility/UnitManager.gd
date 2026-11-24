extends Node
## Inert adapter for legacy scene/resource scripts. Hex has no RPG combat units.
signal active_unit_changed(unit: Unit)

var ally_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var active_unit: Unit
var unit_slot_map: Dictionary = {}


func set_ally_units() -> void:
	pass


func set_enemy_units(_resources: Array[EnemyResource]) -> void:
	pass


func get_all_units() -> Array[Unit]:
	return []


func set_active_unit(_unit: Unit) -> void:
	pass


func get_alive_units(_type: Unit.UnitType = Unit.UnitType.UNSET) -> Array[Unit]:
	return []


func place_units(_slots: Array[UnitSlot]) -> void:
	pass


func map_resource_to_unit(_resource: EntityResource, _type: Unit.UnitType) -> Unit:
	return null


func get_active_unit_slot() -> int:
	return 0


func place_unit_in_slot(_unit: Unit, _slot: UnitSlot) -> void:
	pass


func sync_units_to_resources() -> void:
	pass


func find_unit_by_id(_id: String) -> Unit:
	return null
