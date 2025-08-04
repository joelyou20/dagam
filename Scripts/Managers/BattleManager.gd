extends Node

@onready var BattleUIScene := preload("res://Scenes/UI/Battle/BattleUI.tscn")
var battle_ui: BattleUI = null

var ally_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var current_battle_data: BattleData = null
var is_targeting_mode = false
var pending_action: BattleAction = null  # Store the action that needs a target

@warning_ignore("unused_signal")
signal battle_ended

func build_battle_from_encounter(encounter: EncounterData) -> BattleData:
	
	var party = PartyManager.get_party(false)
	
	var player: PlayerData = PlayerManager.player
	var player_unit = map_resource_to_unit(player, Unit.UnitType.PLAYER)
	ally_units.append(player_unit)
	
	for ally in party:
		var unit: Unit = map_resource_to_unit(ally, Unit.UnitType.ALLY)
		ally_units.append(unit)
	for enemy in encounter.enemies:
		var unit: Unit = map_resource_to_unit(enemy, Unit.UnitType.ENEMY)
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

func map_resource_to_unit(source: Resource, unit_type: Unit.UnitType) -> Unit:
	var unit = Unit.new()
	unit.id = source.id
	unit.title = source.name
	unit.max_hp = source.max_hp
	unit.current_hp = source.max_hp
	unit.speed = source.speed
	unit.attack_power = source.attack_power
	unit.is_player_controlled = unit_type == Unit.UnitType.PLAYER
	unit.type = unit_type
	unit.slot_number = source.slot_number
	unit.visual_scene = source.visual_scene
	unit.battle_scale = source.battle_scale
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
					place_unit_in_slot(unit, slot)
					break
		elif slot.type == UnitSlot.UnitSlotType.ENEMY:
			for slot_unit in enemy_units:
				if slot_unit.slot_number == slot.slot_number:
					unit = slot_unit
					place_unit_in_slot(unit, slot)
					break
		if unit == null:
			continue
		
func place_unit_in_slot(unit_instance, slot: UnitSlot):
	slot.add_child(unit_instance)

	var vis = unit_instance.visual_scene.instantiate()
	slot.node.add_child(vis)
	vis.transform = Transform3D.IDENTITY  # Or set local position manually
	vis.scale = Vector3.ONE * unit_instance.battle_scale
	
	# Look for any Area3D children that were added to the slot (not just unit_instance children)
	for child in slot.get_children():
		if child is Area3D and child != slot:  # Don't disable the slot itself
			child.input_ray_pickable = false
			print("Disabled input on: ", child.name)
	
	slot.unit = unit_instance

func start_targeting(action: BattleAction):
	is_targeting_mode = true
	pending_action = action
	print("Targeting mode started for action: ", action)

func end_targeting():
	is_targeting_mode = false
	pending_action = null
	# Clear any existing arrows
	UnitSlot.clear_arrow()
	print("Targeting mode ended")

func select_target(target_unit):
	if is_targeting_mode and pending_action:
		# Execute the action on the target
		execute_action(pending_action, target_unit)
		end_targeting()
	else:
		# Regular selection without targeting
		print("Selected unit: ", target_unit.name)

func execute_action(action: BattleAction, target: Unit):
	if action.get_action_type() == BattleAction.ActionType.ATTACK:
		var source_slot = action.get_source_slot()
		var source_unit = ally_units[source_slot - 1]
		target.take_damage(source_unit.attack_power)
		print(target.title + " took " + str(source_unit.attack_power) + " points of damage!")

func get_active_unit_slot() -> int:
	# TODO: Once the turn system is designed return whoever is acting. For now will default to slot 1
	return 1
	
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
