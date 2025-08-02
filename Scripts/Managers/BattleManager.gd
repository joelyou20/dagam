extends Node


var ally_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var current_battle_data: BattleData = null

func build_battle_from_encounter(encounter: EncounterData) -> BattleData:
	
	var party = PartyManager.get_party(false)
	
	var player: PlayerData = PlayerManager.player
	var player_unit = build_unit(player, Unit.UnitType.PLAYER)
	ally_units.append(player_unit)
	
	for ally in party:
		var unit: Unit = build_unit(ally, Unit.UnitType.ALLY)
		ally_units.append(ally)
	for enemy in encounter.enemies:
		var unit: Unit = build_unit(enemy, Unit.UnitType.ENEMY)
		enemy_units.append(enemy)
	
	var battleData: BattleData = BattleData.new()
	battleData.set_units(ally_units, enemy_units)
	current_battle_data = battleData
	
	return battleData

func build_unit(source: Resource, unit_type: Unit.UnitType) -> Unit:
	var unit = Unit.new()
	unit.title = source.name
	unit.max_hp = source.max_hp
	unit.current_hp = source.max_hp
	unit.speed = source.speed
	unit.attack_power = source.attack_power
	unit.is_player_controlled = unit_type == Unit.UnitType.PLAYER
	unit.type = unit_type
	unit.slot_number = source.slot_number
	unit.visual_scene = source.visual_scene
	return unit
	
func place_ally(slot: UnitSlot):
	if not slot:
		return

	var unit: Unit = null
	for slot_unit in ally_units:
		if slot_unit.slot_number == slot.slot_number:
			unit = slot_unit
			break

	if unit == null:
		return

	var vis = unit.visual_scene.instantiate()
	slot.node.add_child(vis)
	vis.transform = Transform3D.IDENTITY  # Or set local position manually


func place_enemy(slot: UnitSlot):
	if not slot:
		push_error("Enemy slot " + str(slot.slot_number) + " does not exist.")
		return

	var matching_units = enemy_units.filter(func(u): u.slot_number == slot.slot_number)
	var unit: Unit = null
	if matching_units.size() > 0:
		unit = matching_units.front()
	if not unit:
		return
		
	var vis = unit.visual_scene.instantiate()
	slot.node.add_child(vis)
	vis.transform = Transform3D.IDENTITY  # Or set local position manually

func begin_battle():
	InteractionHandler.block("battle")

	var cam = get_node_or_null("BattleCamera")
	if cam and cam is Camera3D:
		cam.current = true

func end_battle():
	InteractionHandler.unblock("battle")
	
	var cam = get_node_or_null("BattleCamera")
	if cam and cam is Camera3D:
		cam.queue_free()
		
	emit_signal("battle_ended")
