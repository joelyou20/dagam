extends "res://Scripts/Compatibility/LegacyBattleFacade.gd"
## Owns Hex encounter outcomes and overworld restoration. No unit combat runs here.
signal battle_ended

var current_battle_data: BattleData
var hex_encounter_active := false
var pre_battle_player_position := Vector3.ZERO
var last_battle_time := -100.0
var battle_cooldown_duration := 5.0
var base_flee_chance := 0.5
var _hex_player_state: Dictionary = {}
var _finishing_hex := false

func can_start_battle(force: bool = false) -> bool:
	if current_battle_data != null or HexManager.is_encounter():
		return false

	return force or Time.get_ticks_msec() / 1000.0 - last_battle_time >= battle_cooldown_duration

func build_battle_from_encounter(encounter: EncounterData, enemy_id: String = "") -> BattleData:
	if encounter == null or not HexManager.ensure_match() or not can_start_battle():
		return null

	var deck_exists: bool = HexManager.session.catalog.enemies.any(
		func(d): return d.id == encounter.hex_deck_id
	)

	if not deck_exists:
		push_warning("Unknown encounter Hex deck: " + encounter.hex_deck_id)

		return null

	var reward := 0

	for enemy in encounter.enemies:
		if enemy != null:
			reward += enemy.xp_reward

	var scene_path: String = (
		SceneManager.current_scene.scene_file_path
		if is_instance_valid(SceneManager.current_scene)
		else ""
	)
	var metadata := {
		"enemy_id": enemy_id,
		"deck_id": encounter.hex_deck_id,
		"xp_reward": reward,
		"scene_path": scene_path,
		"name":
		", ".join(encounter.enemies.filter(func(e): return e != null).map(func(e): return e.name))
	}
	var natural: Array = []

	for slot in range(6):
		var terrain := (
			encounter.hex_terrains[slot] if slot < encounter.hex_terrains.size() else "Earth"
		)

		natural.append({"types": [terrain], "locked": slot in encounter.locked_hexes})

	metadata["planes"] = [natural.duplicate(true), natural.duplicate(true)]
	var player = PlayerManager.get_player_node()

	if is_instance_valid(player):
		metadata["position"] = {
			"x": player.global_position.x,
			"y": player.global_position.y,
			"z": player.global_position.z
		}

	if not HexManager.start_encounter(metadata):
		return null

	current_battle_data = BattleData.new()
	current_battle_data.xp_reward = reward
	current_battle_data.flee_chance = base_flee_chance
	hex_encounter_active = true
	_freeze_hex_player()
	HexManager.open_battle()

	return current_battle_data

func begin_battle() -> void:
	HexManager.open_battle()

func end_battle() -> void:
	if hex_encounter_active:
		_end_hex_encounter()

func attempt_to_flee() -> void:
	if hex_encounter_active and randf() < base_flee_chance:
		current_battle_data.was_fled = true
		_end_hex_encounter()


# Hex encounters stay in the current world: only the UI and player controls change.

func _freeze_hex_player() -> void:
	InteractionHandler.block("battle")
	var player = PlayerManager.get_player_node()

	if not is_instance_valid(player):
		return

	pre_battle_player_position = player.global_position
	_hex_player_state = {
		"visible": player.visible,
		"process": player.is_processing(),
		"physics": player.is_physics_processing(),
		"layer": player.collision_layer,
		"mask": player.collision_mask
	}
	player.visible = false
	player.set_process(false)
	player.set_physics_process(false)
	player.collision_layer = 0
	player.collision_mask = 0

	if player is CharacterBody3D:
		player.velocity = Vector3.ZERO

func _restore_hex_player(restore_position: bool = true) -> void:
	InteractionHandler.unblock("battle")
	var player = PlayerManager.get_player_node()

	if is_instance_valid(player) and not _hex_player_state.is_empty():
		player.visible = _hex_player_state.visible
		player.set_process(_hex_player_state.process)
		player.set_physics_process(_hex_player_state.physics)
		player.collision_layer = _hex_player_state.layer
		player.collision_mask = _hex_player_state.mask

		if restore_position:
			player.global_position = pre_battle_player_position

		if player is CharacterBody3D:
			player.velocity = Vector3.ZERO

	_hex_player_state.clear()

func _end_hex_encounter() -> void:
	if _finishing_hex or current_battle_data == null:
		return

	var winner = HexManager.session.state.get("winner")

	if winner == null and not current_battle_data.was_fled:
		return

	_finishing_hex = true
	var data := current_battle_data

	data.outcome = (
		"fled"
		if data.was_fled
		else "victory" if winner == 0 else "draw" if winner == -1 else "defeat"
	)

	if data.outcome == "victory":
		PlayerManager.add_xp(data.xp_reward)

	hex_encounter_active = false
	current_battle_data = null
	HexManager.restore_practice()
	HexManager.close_battle(true)
	_restore_hex_player()
	last_battle_time = Time.get_ticks_msec() / 1000.0
	battle_ended.emit()
	data.free()
	_finishing_hex = false

func on_hex_state_loaded() -> void:
	# Preserve the player position already restored by GameStateManager.
	_restore_hex_player(false)
	hex_encounter_active = false

	if current_battle_data != null:
		current_battle_data.free()
		current_battle_data = null

	EnemyManager.clear_encounter_binding()

	if HexManager.is_encounter():
		resume_hex_encounter()

func resume_hex_encounter() -> void:
	if hex_encounter_active or not HexManager.is_encounter():
		return

	var metadata: Dictionary = HexManager.encounter_metadata()
	var scene_path: String = (
		SceneManager.current_scene.scene_file_path
		if is_instance_valid(SceneManager.current_scene)
		else ""
	)
	var enemy = EnemyManager.find_enemy(metadata.get("enemy_id", ""))

	if (
		metadata.get("scene_path", "") != scene_path
		or (not str(metadata.get("enemy_id", "")).is_empty() and not is_instance_valid(enemy))
	):
		HexManager.restore_practice()

		return

	current_battle_data = BattleData.new()
	current_battle_data.xp_reward = int(metadata.get("xp_reward", 0))
	current_battle_data.flee_chance = base_flee_chance
	hex_encounter_active = true
	_freeze_hex_player()
	var position: Dictionary = metadata.get("position", {})

	if position.has("x"):
		pre_battle_player_position = Vector3(position.x, position.y, position.z)

	EnemyManager.bind_encounter(metadata.get("enemy_id", ""), current_battle_data)
	HexManager.open_battle.call_deferred()
