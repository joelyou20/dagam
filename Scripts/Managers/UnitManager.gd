extends Node

var ally_units: Array[Unit] = []
var enemy_units: Array[Unit] = []

var active_unit: Unit = null
var unit_slot_map: Dictionary = {}

signal active_unit_changed(unit: Unit)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ally_units = []
	enemy_units = []
		
	sync_units_to_resources()
	
func set_ally_units():
	var party = PartyManager.get_party(false)
	var player: PlayerResource = PlayerManager.player
	var player_unit = map_resource_to_unit(player, Unit.UnitType.PLAYER)
	ally_units.append(player_unit)
	
	for ally in party:
		var unit = map_resource_to_unit(ally, Unit.UnitType.ALLY)
		ally_units.append(unit)
	
func set_enemy_units(entityResources: Array[EnemyResource]):
	for enemy in entityResources:
		var unit = map_resource_to_unit(enemy, Unit.UnitType.ENEMY)
		enemy_units.append(unit)

func get_all_units() -> Array[Unit]:
	var all_units: Array[Unit] = []
	all_units.append_array(ally_units.filter(func(u): return u != null))
	all_units.append_array(enemy_units.filter(func(u): return u != null))
	
	return all_units;
	
func set_active_unit(u: Unit) -> void:
	active_unit = u
	emit_signal("active_unit_changed", u)
			
func get_alive_units(type: Unit.UnitType = Unit.UnitType.UNSET) -> Array[Unit]:
	var out: Array[Unit] = []
	var units = get_all_units()
	
	if type == Unit.UnitType.UNSET:
		out.append_array(units)
	else:
		# also prune freed/queued refs from the original array (optional but helpful)
		for i in range(units.size() - 1, -1, -1):
			var u: Unit = units[i]
			if not is_instance_valid(u) or u.is_queued_for_deletion():
				units.remove_at(i)
			elif u.is_alive and u.type == type:
				out.append(u)
	return out

func place_units(slots: Array[UnitSlot]):
	if not slots:
		return

	var unit: Unit
	for slot in slots:
		unit = null
		if slot.type == UnitSlot.UnitSlotType.ALLY:
			for slot_unit in ally_units:
				if slot_unit.resource.slot_number == slot.slot_number:
					unit = slot_unit
					place_unit_in_slot(unit, slot)
					break
		elif slot.type == UnitSlot.UnitSlotType.ENEMY:
			for slot_unit in enemy_units:
				if slot_unit.resource.slot_number == slot.slot_number:
					unit = slot_unit
					place_unit_in_slot(unit, slot)
					break
		if unit == null:
			continue
			
func map_resource_to_unit(source: EntityResource, unit_type: Unit.UnitType) -> Unit:
	var unit = Unit.new()
	unit.resource = source
	unit.type = unit_type
	
	return unit
	
func get_active_unit_slot() -> int:
	if active_unit and unit_slot_map.has(active_unit):
		var slot: UnitSlot = unit_slot_map[active_unit]
		return slot.slot_number
	return 1
	
func place_unit_in_slot(unit: Unit, slot: UnitSlot):
	slot.add_child(unit)

	var vis = unit.resource.visual_scene.instantiate()
	slot.node.add_child(vis)
	vis.transform = Transform3D.IDENTITY
	vis.scale = Vector3.ONE * unit.resource.battle_scale

	for child in slot.get_children():
		if child is Area3D and child != slot:
			child.input_ray_pickable = false

	slot.unit = unit

	unit_slot_map[unit] = slot

func sync_units_to_resources():
	for unit in ally_units:
		var resource
		if unit.resource.id == PlayerManager.player.id:
			resource = PlayerManager.player
		else:
			resource = PartyManager.get_member_by_id(unit.resource.id)

		if resource:
			_update_resource_from_unit(resource, unit)

func _update_resource_from_unit(resource: Resource, unit: Unit):
	# Core combat stats
	resource.current_hp = unit.resource.current_hp
	#if "current_mp" in resource and "current_mp" in unit:
		#resource.current_mp = unit.current_mp

	# Experience / level
	#if "experience" in resource and "experience" in unit:
		#resource.experience = unit.experience
	#if "level" in resource and "level" in unit:
		#resource.level = unit.level

	# TODO: Add syncing for status effects, buffs, debuffs
	# if "status_effects" in resource and "status_effects" in unit:
	#     resource.status_effects = unit.status_effects.duplicate(true)

func find_unit_by_id(id: String) -> Unit:
	var all_units: Array[Unit] = get_all_units()
	for unit in all_units:
		if unit.resource.id == id:
			return unit
	return null
