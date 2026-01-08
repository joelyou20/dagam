extends Node

@onready var BattleUIScene := preload("res://Scenes/UI/Battle/BattleUI.tscn")

var _unit_manager: UnitManager
var _turn_order_manager: TurnOrderManager
var _battle_ai_executor: BattleAiExecutor

var battle_ui: BattleUI = null

var current_battle_data: BattleData = null
var is_targeting_mode = false
var pending_action: BattleAction = null  # Store the action that needs a target

var pre_battle_scene_path: String = ""
var pre_battle_player_position: Vector3 = Vector3.ZERO

var last_battle_time := -100.0  # some time far in the past
var battle_cooldown_duration := 5.0  # seconds
var player_collision_layer: int
var player_collision_mask: int

var base_flee_chance: float = 0.5
signal battle_ended

func _ready():
	_unit_manager = UnitManager
	_turn_order_manager = TurnOrderManager
	_battle_ai_executor = BattleAiExecutor

#region Public Methods
func can_start_battle(force: bool = false) -> bool:
	return force or (Time.get_ticks_msec() / 1000.0 - last_battle_time >= battle_cooldown_duration)

func build_battle_from_encounter(encounter: EncounterData) -> BattleData:
	if not can_start_battle():
		push_warning("Tried to start a battle too soon after previous one.")
		return null
		
	current_battle_data = null
	pre_battle_scene_path = SceneManager.current_scene.scene_file_path
	var player_node := PlayerManager.get_player_node()
	if player_node:
		pre_battle_player_position = player_node.global_transform.origin
	else:
		push_error("Player node not found. Cannot save position before battle.")
	
	SceneManager.load_scene(encounter.battle_scene_path, true, true, "", 0.1)
	_unit_manager.set_ally_units()
	_unit_manager.set_enemy_units(encounter.enemies)
		
	var battleData: BattleData = BattleData.new()
	battleData.set_units(_unit_manager.ally_units, _unit_manager.enemy_units)
	battleData.set_xp_reward()
	battleData.flee_chance = base_flee_chance
	current_battle_data = battleData
	
	return battleData

func ensure_battle_ui():
	if battle_ui == null:
		battle_ui = BattleUIScene.instantiate()
		get_tree().get_root().add_child(battle_ui)
		battle_ui.tree_exited.connect(func(): battle_ui = null)

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
		print("Selected unit: ", target_unit.resource.name)

# TODO: Expand on this when I implement skills and weapon types
func execute_action(action: BattleAction, target: Unit):
	var active_unit = _unit_manager.active_unit
	
	if active_unit == null:
		push_error("Active unit is null")
	
	match action.get_action_type():
		BattleAction.ActionType.ATTACK:
			var source_unit: Unit = active_unit
			if source_unit == null:
				# Backward-compat: fallback to old source-slot logic if needed
				var source_slot = action.get_source_slot()
				if source_slot > 0 and source_slot - 1 < _unit_manager.ally_units.size():
					source_unit = _unit_manager.ally_units[source_slot - 1]
				else:
					push_error("No active unit and invalid source slot; cannot ATTACK.")
					return

			# On-attack equipment effects (actor)
			var on_attack_effects = EquipmentManager.get_equipment_on_attack_effects(source_unit)
			for effect in on_attack_effects:
				effect.run(target)
				if !target.is_alive:
					break

			# Pull stats from actor/target correctly (ally vs enemy)
			var phys_atk = (
				EquipmentManager.get_equip_stats(source_unit.resource)[StatOptions.Keys.PHYS_ATK]
				if source_unit.type != Unit.UnitType.ENEMY
				else source_unit.resource.physical_attack
			)

			var phys_def = (
				EquipmentManager.get_equip_stats(target.resource)[StatOptions.Keys.PHYS_DEF]
				if target.type != Unit.UnitType.ENEMY
				else target.resource.physical_defense
			)

			var damage_taken = max(0, phys_atk - phys_def)
			target.take_damage(damage_taken)
			print(target.resource.name + " took " + str(damage_taken) + " points of damage!")

		BattleAction.ActionType.ITEM:
			var item = action.get_item()
			_apply_item_to_target(item, target)
		
	# Recalculate turn order in case speeds/statuses changed, then advance to next unit
	_turn_order_manager.finish_turn(active_unit)
	_update_active_unit()
	_check_battle_end()

func attempt_to_flee():
	for ally in _unit_manager.ally_units:
		var on_flee_effects = EquipmentManager.get_equipment_on_flee_effects(ally)
		for effect in on_flee_effects:
			effect.run()
			
	var flee_chance = current_battle_data.flee_chance
	
	var party_speed := 0
	for unit in _unit_manager.ally_units.filter(func(u): return is_instance_valid(u) && u.is_alive):
		party_speed += unit.resource.speed
	var enemy_speed := 0
	for unit in _unit_manager.enemy_units.filter(func(u): return is_instance_valid(u) && u.is_alive):
		enemy_speed += unit.resource.speed

	if party_speed > enemy_speed:
		flee_chance += 0.2
	else:
		flee_chance -= 0.2
	flee_chance = clamp(flee_chance, 0.1, 0.95)

	if randf() < flee_chance:
		print("Flee successful!")
		if current_battle_data:
			current_battle_data.was_fled = true
		end_battle()
	else:
		print("Flee failed!")

func begin_battle():
	InteractionHandler.block("battle")

	var cam = get_node_or_null("BattleCamera")
	if cam and cam is Camera3D:
		cam.current = true

	ensure_battle_ui()
	battle_ui.show_ui()
	battle_ui.populate_enemies(_unit_manager.enemy_units)
	battle_ui.populate_ally_info_container(_unit_manager.ally_units)

	var player_node := PlayerManager.get_player_node()
	player_collision_layer = player_node.collision_layer
	player_collision_mask = player_node.collision_mask
	_disable_overworld_player()
	
	_turn_order_manager.setup(_unit_manager.get_all_units())
	_update_active_unit()

func end_battle():
	_unit_manager.sync_units_to_resources()
	
	InteractionHandler.unblock("battle")
	
	var cam = get_node_or_null("BattleCamera")
	if cam and cam is Camera3D:
		cam.queue_free()
	battle_ui.hide_ui()
	battle_ui.queue_free()
	
	if pre_battle_scene_path != "":
		SceneManager.load_scene(pre_battle_scene_path, true, true, "", 0.1)
		await SceneManager.scene_loaded  # Wait for scene to load
		
		# Re-enable player (happens while screen is black, no blip)
		_enable_overworld_player()
		
		# Restore player position
		var player_node := PlayerManager.get_player_node()
		if player_node:
			player_node.global_transform.origin = pre_battle_player_position
		else:
			push_error("Player node not found after battle. Cannot restore position.")
	else:
		push_error("No pre-battle scene path stored. Cannot return to previous scene.")
	
	# Clear stale data
	_unit_manager.ally_units.clear()
	_unit_manager.enemy_units.clear()
	current_battle_data = null
	last_battle_time = Time.get_ticks_msec() / 1000.0
	
	battle_ended.emit()
	

#endregion
#region Private Methods

func _apply_item_to_target(item: ItemResource, target: Unit):
	print("Using %s on %s" % [item.name, target.resource.name])
	if item and target:
		var temp_resource: EntityResource = target.resource.duplicate()
		InventoryManager.use_item(item, target.resource)
		var hp_difference = temp_resource.current_hp - target.resource.current_hp
		if hp_difference != 0:
			target.hp_change.emit(hp_difference)

func _check_battle_end() -> bool:
	var all_enemies_dead := _unit_manager.enemy_units.filter(func(u):
		return is_instance_valid(u) and u.is_alive
	).is_empty()

	var all_allies_dead := _unit_manager.ally_units.filter(func(u):
		return is_instance_valid(u) and u.is_alive
	).is_empty()

	if all_enemies_dead:
		print("All enemies defeated! Ending battle.")
		PartyManager.grant_xp(current_battle_data.xp_reward)
		end_battle()
		return true
	elif all_allies_dead:
		print("All allies defeated! Ending battle.")
		end_battle()
		return true
	
	return false

func _disable_overworld_player():
	var player_node := PlayerManager.get_player_node()
		
	player_node.visible = false
	player_node.set_process(false)
	player_node.set_physics_process(false)
	player_node.set_collision_layer(0)
	player_node.set_collision_mask(0)

func _enable_overworld_player():
	var player_node := PlayerManager.get_player_node()
	
	player_node.visible = true
	player_node.set_process(true)
	player_node.set_physics_process(true)
	player_node.set_collision_layer(player_collision_layer)
	player_node.set_collision_mask(player_collision_mask)
	
# TODO Gets all units twice here... May not care?
func _update_active_unit():
	var id: String = _turn_order_manager.turn_order_queue.front()
	var unit: Unit = _unit_manager.find_unit_by_id(id)
	_unit_manager.set_active_unit(unit)
	_battle_ai_executor.take_turn(_unit_manager.active_unit)
	
#endregion
