extends Node

var active_enemy_id: String = ""
var active_battle_data: BattleData = null
var enemy_scene_path: String = ""  # Store the scene path where the enemy was

func _ready():
	BattleManager.connect("battle_ended", Callable(self, "_on_battle_ended"))

func start_battle_from_enemy(enemy: Enemy):
	if not is_instance_valid(enemy) or HexManager.is_encounter() or not BattleManager.can_start_battle():
		if not HexManager.is_encounter(): InteractionHandler.unblock("Enemy")
		return
	enemy.active = false
	var data := BattleManager.build_battle_from_encounter(enemy.encounter, enemy.id)
	if data == null:
		enemy.active = not HexManager.is_encounter() or active_enemy_id != enemy.id
		if not HexManager.is_encounter(): InteractionHandler.unblock("Enemy")
		return
	bind_encounter(enemy.id, data)

func bind_encounter(id: String, data: BattleData) -> void:
	active_enemy_id = id
	active_battle_data = data
	var enemy = find_enemy(id)
	if is_instance_valid(enemy):
		enemy.active = false
		enemy_scene_path = enemy.scene_file_path

func clear_encounter_binding() -> void:
	active_enemy_id = ""
	active_battle_data = null
	enemy_scene_path = ""
	InteractionHandler.unblock("Enemy")

func find_enemy(id: String) -> Enemy:
	return _find_enemy_by_id(id) if not id.is_empty() else null

func _on_battle_ended():
	var enemy = find_enemy(active_enemy_id)
	var victory: bool = active_battle_data != null and active_battle_data.outcome == "victory"
	clear_encounter_binding()
	if not is_instance_valid(enemy): return
	if victory:
		enemy.queue_free()
	else:
		var timer := Timer.new()
		timer.one_shot = true
		timer.wait_time = maxf(0.001, enemy.fled_reactivate_cooldown)
		enemy.add_child(timer)
		timer.timeout.connect(func():
			if is_instance_valid(enemy): enemy.active = true
			timer.queue_free())
		timer.start()

func _find_enemy_by_id(id: String) -> Enemy:
	# First try the expected location
	var world = get_tree().get_root().get_node_or_null("World/SceneRoot")
	if not world:
		return null
	
	# Search recursively through the entire scene tree starting from SceneRoot
	var enemy = _find_enemy_recursive(world, id)
	if enemy:
		return enemy
	
	# If not found, try searching from root as fallback
	enemy = _find_enemy_recursive(get_tree().get_root(), id)
	if enemy:
		return enemy
	
	return null

func _find_enemy_recursive(node: Node, id: String) -> Enemy:
	# Check if this node is the enemy we're looking for
	if node is Enemy and node.id == id:
		return node
	
	# Search children recursively
	for child in node.get_children():
		var result = _find_enemy_recursive(child, id)
		if result:
			return result
	
	return null
