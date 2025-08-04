extends Node

@onready var BattleUIScene := preload("res://Scenes/UI/Battle/BattleUI.tscn")
var battle_ui: BattleUI = null

var ally_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var current_battle_data: BattleData = null

signal battle_ended

func build_battle_from_encounter(encounter: EncounterData) -> BattleData:
	
	var party = PartyManager.get_party(false)
	
	var player: PlayerData = PlayerManager.player
	var player_unit = build_unit(player, Unit.UnitType.PLAYER)
	ally_units.append(player_unit)
	
	for ally in party:
		var unit: Unit = build_unit(ally, Unit.UnitType.ALLY)
		ally_units.append(unit)
	for enemy in encounter.enemies:
		var unit: Unit = build_unit(enemy, Unit.UnitType.ENEMY)
		enemy_units.append(unit)
	
	var battleData: BattleData = BattleData.new()
	battleData.set_units(ally_units, enemy_units)
	current_battle_data = battleData
	
	return battleData

func ensure_battle_ui():
	if battle_ui == null:
		battle_ui = BattleUIScene.instantiate()
		get_tree().get_root().add_child(battle_ui)
		battle_ui.tree_exited.connect(func(): battle_ui = null)

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

func place_units(slots: Array[UnitSlot]):
	if not slots:
		return

	var unit: Unit
	for slot in slots:
		unit = null
		if slot.type == UnitSlot.UnitSlotType.ALLY:
			for slot_unit in ally_units:
				if slot_unit.slot_number == slot.slot_number:
					unit = slot_unit
					slot.unit = slot_unit
					break
		elif slot.type == UnitSlot.UnitSlotType.ENEMY:
			for slot_unit in enemy_units:
				if slot_unit.slot_number == slot.slot_number:
					unit = slot_unit
					slot.unit = slot_unit
					break
		if unit == null:
			continue

		var vis = unit.visual_scene.instantiate()
		slot.node.add_child(vis)
		vis.transform = Transform3D.IDENTITY  # Or set local position manually
		
func select_target(unit: Unit):
	print("Target selected: " + unit.title)
	
func begin_battle():
	InteractionHandler.block("battle")

	var cam = get_node_or_null("BattleCamera")
	if cam and cam is Camera3D:
		cam.current = true

	# Show the battle UI
	ensure_battle_ui()
	battle_ui.show_ui()
	battle_ui.populate_enemies(enemy_units)

func end_battle():
	InteractionHandler.unblock("battle")
	
	var cam = get_node_or_null("BattleCamera")
	if cam and cam is Camera3D:
		cam.queue_free()
		
	emit_signal("battle_ended")
