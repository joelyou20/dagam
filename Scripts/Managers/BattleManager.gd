extends Node

@onready var BattleUIScene := preload("res://Scenes/UI/Battle/BattleUI.tscn")
var battle_ui: BattleUI = null

var ally_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var current_battle_data: BattleData = null
var is_targeting_mode = false
var pending_action: BattleAction = null  # Store the action that needs a target

var pre_battle_scene_path: String = ""
var pre_battle_player_position: Vector3 = Vector3.ZERO

var last_battle_time := -100.0  # some time far in the past
var battle_cooldown_duration := 5.0  # seconds
var player_collision_layer: int
var player_collision_mask: int

@warning_ignore("unused_signal")
signal battle_started
@warning_ignore("unused_signal")
signal battle_ended

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
	var party = PartyManager.get_party(false)
	
	var player: PlayerResource = PlayerManager.player
	ally_units = []
	enemy_units = []

	var player_unit = map_resource_to_unit(player, Unit.UnitType.PLAYER)
	ally_units.append(player_unit)

	for ally in party:
		var unit = map_resource_to_unit(ally, Unit.UnitType.ALLY)
		ally_units.append(unit)

	for enemy in encounter.enemies:
		var unit = map_resource_to_unit(enemy, Unit.UnitType.ENEMY)
		enemy_units.append(unit)
	
	var battleData: BattleData = BattleData.new()
	battleData.set_units(ally_units, enemy_units)
	battleData.set_xp_reward()
	current_battle_data = battleData
	
	return battleData

func ensure_battle_ui():
	if battle_ui == null:
		battle_ui = BattleUIScene.instantiate()
		get_tree().get_root().add_child(battle_ui)
		battle_ui.tree_exited.connect(func(): battle_ui = null)

func map_resource_to_unit(source: EntityResource, unit_type: Unit.UnitType) -> Unit:
	var unit = Unit.new()
	unit.resource = source
	unit.type = unit_type
	
	return unit

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
		
func place_unit_in_slot(unit: Unit, slot: UnitSlot):
	slot.add_child(unit)

	var vis = unit.resource.visual_scene.instantiate()
	slot.node.add_child(vis)
	vis.transform = Transform3D.IDENTITY  # Or set local position manually
	vis.scale = Vector3.ONE * unit.resource.battle_scale
	
	# Look for any Area3D children that were added to the slot (not just unit_instance children)
	for child in slot.get_children():
		if child is Area3D and child != slot:  # Don't disable the slot itself
			child.input_ray_pickable = false
			print("Disabled input on: ", child.name)
	
	slot.unit = unit

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
	match action.get_action_type():
		BattleAction.ActionType.ATTACK:
			var source_slot = action.get_source_slot()
			var source_unit = ally_units[source_slot - 1]
			
			var phys_atk = (
				EquipmentManager.get_equip_stats(source_unit.resource)[StatOptions.Keys.PHYS_ATK] 
				if source_unit.type != Unit.UnitType.ENEMY 
				else source_unit.resource.physical_attack
			) 
			var phys_def = (
				EquipmentManager.get_equip_stats(target.resource)[StatOptions.Keys.PHYS_DEF]
				if source_unit.type != Unit.UnitType.ENEMY 
				else source_unit.resource.physical_defense
			) 
			
			var damage_taken = phys_atk - phys_def
			target.take_damage(damage_taken)
			print(target.resource.name + " took " + str(damage_taken) + " points of damage!")
			_check_battle_end()

		BattleAction.ActionType.ITEM:
			var item = action.get_item()
			_apply_item_to_target(item, target)
			_check_battle_end()

func _apply_item_to_target(item: ItemResource, target: Unit):
	print("Using %s on %s" % [item.name, target.resource.name])
	if item and target:
		InventoryManager.use_item(item, target.resource)

func _check_battle_end():
	var all_enemies_dead := enemy_units.filter(func(u):
		return is_instance_valid(u) and u.is_alive
	).is_empty()

	var all_allies_dead := ally_units.filter(func(u):
		return is_instance_valid(u) and u.is_alive
	).is_empty()

	if all_enemies_dead:
		print("All enemies defeated! Ending battle.")
		PartyManager.grant_xp(current_battle_data.xp_reward)
		end_battle()
	elif all_allies_dead:
		print("All allies defeated! Ending battle.")
		end_battle()

func get_active_unit_slot() -> int:
	# TODO: Once the turn system is designed return whoever is acting. For now will default to slot 1
	return 1

func _sync_units_to_resources():
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

func attempt_to_flee():
	var flee_chance := 0.5
	var party_speed := 0
	for unit in ally_units.filter(func(u): return is_instance_valid(u) && u.is_alive):
		party_speed += unit.resource.speed
	var enemy_speed := 0
	for unit in enemy_units.filter(func(u): return is_instance_valid(u) && u.is_alive):
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

	# Show the battle UI
	ensure_battle_ui()
	battle_ui.show_ui()
	battle_ui.populate_enemies(enemy_units)
	
	var player_node := PlayerManager.get_player_node()
	player_collision_layer = player_node.collision_layer
	player_collision_mask = player_node.collision_mask
	_disable_overworld_player()

func end_battle():
	_sync_units_to_resources()
	
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
	ally_units.clear()
	enemy_units.clear()
	current_battle_data = null
	last_battle_time = Time.get_ticks_msec() / 1000.0
	
	# Emit signal for enemy cleanup AFTER everything is ready
	emit_signal("battle_ended")

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
