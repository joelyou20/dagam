extends Node

@export var player_resource_path: String = "res://Resources/player.tres"

var player: PlayerResource

func _ready():
	# Load default player template on startup
	player = load(player_resource_path) as PlayerResource
	if player == null:
		push_error("Failed to load player resource at: " + player_resource_path)
		return
	
	# If new game, reset HP etc.
	_reset_runtime_stats()

func _reset_runtime_stats():
	player.current_hp = player.max_hp
	# Reset other runtime values if needed

func get_player_node() -> Node:
	return $"/root/World/Player"

func add_xp(amount: int):
	player.experience += amount
	print("XP:", player.experience)

func set_hp(amount: int):
	player.current_hp = clamp(amount, 0, player.max_hp)
	if player.current_hp == player.max_hp:
		print("Player health at max: " + str(player.current_hp))
	else:
		print("HP: ", player.current_hp)

func add_hp(amount: int):
	set_hp(player.current_hp + amount)

# --- SAVE / LOAD ---

func save_player() -> Dictionary:
	return {
		"id": player.id,
		"name": player.name,
		"level": player.level,
		"experience": player.experience,
		"current_hp": player.current_hp,
		"max_hp": player.max_hp,
		"attack_power": player.attack_power,
		"speed": player.speed,
		"visual_scene": player.visual_scene.resource_path
	}

func load_player(data: Dictionary):
	if not player:
		push_error("Player resource not loaded before load_player_data()")
		return
	
	player.id = data.get("id", player.id)
	player.name = data.get("name", player.name)
	player.level = data.get("level", player.level)
	player.experience = data.get("experience", player.experience)
	player.current_hp = data.get("current_hp", player.current_hp)
	player.max_hp = data.get("max_hp", player.max_hp)
	player.attack_power = data.get("attack_power", player.attack_power)
	player.speed = data.get("speed", player.speed)
	
	var scene_path = data.get("visual_scene", "")
	if scene_path != "":
		player.visual_scene = load(scene_path)
