extends Node

var active_enemy_id: String = ""
var active_battle_data: BattleData = null
var enemy_scene_path: String = ""  # Store the scene path where the enemy was

func _ready():
	BattleManager.connect("battle_ended", Callable(self, "_on_battle_ended"))

func start_battle_from_enemy(enemy: Enemy):
	active_enemy_id = enemy.id
	enemy_scene_path = enemy.get_scene_file_path()  # Store where this enemy came from
	enemy.active = false
	
	active_battle_data = BattleManager.build_battle_from_encounter(enemy.encounter)
	
	if active_battle_data == null:
		enemy.active = true
		InteractionHandler.unblock("Enemy")
		active_enemy_id = ""
		enemy_scene_path = ""
		return
	
	await SceneManager.fade_layer.fade_completed

func _on_battle_ended():
	if active_enemy_id.is_empty():
		return
	
	if active_battle_data == null:
		# Clean up anyway
		active_enemy_id = ""
		return
	
	InteractionHandler.unblock("Enemy")
	
	# Search for the enemy
	var enemy = _find_enemy_by_id(active_enemy_id)
		
	if not active_battle_data.was_fled:
		enemy.queue_free()
	else:
		await get_tree().create_timer(enemy.fled_reactivate_cooldown).timeout
		if is_instance_valid(enemy):
			enemy.active = true
	
	# Clean up
	active_enemy_id = ""
	active_battle_data = null
	enemy_scene_path = ""

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
