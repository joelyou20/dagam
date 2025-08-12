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
		"max_hp": player.max_hp,
		"current_hp": player.current_hp,
		"slot_number": player.slot_number,
		"battle_scale": player.battle_scale,
		"visual_scene": player.visual_scene.resource_path,
		"portrait_texture": player.portrait_texture.resource_path,
		
		"inventory": ResUtil.resources_to_path_array(player.inventory),
		"inventory_slots": player.inventory_slots,
		
		"level": player.level,
		"experience": player.experience,
		"xp_to_next_level": player.xp_to_next_level,
		"xp_growth_rate": player.xp_growth_rate,
		
		"speed": player.speed,
		"physical_attack": player.physical_attack,
		"physical_defense": player.physical_defense,
		"magical_attack": player.magical_attack,
		"magical_defense": player.magical_defense,
		
		"head_equipment": ResUtil.resource_to_path_or_empty(player.head_equipment),
		"chest_equipment": ResUtil.resource_to_path_or_empty(player.chest_equipment),
		"back_equipment": ResUtil.resource_to_path_or_empty(player.back_equipment),
		"feet_equipment": ResUtil.resource_to_path_or_empty(player.feet_equipment),
		"hands_equipment": ResUtil.resource_to_path_or_empty(player.hands_equipment),
		"main_weapon_equipment": ResUtil.resource_to_path_or_empty(player.main_weapon_equipment),
		"offhand_weapon_equipment": ResUtil.resource_to_path_or_empty(player.offhand_weapon_equipment),
	}

func load_player(data: Dictionary):
	if not player:
		push_error("Player resource not loaded before load_player_data()")
		return
	
	player.id = data.get("id", player.id)
	player.name = data.get("name", player.name)
	player.current_hp = data.get("current_hp", player.current_hp)
	player.max_hp = data.get("max_hp", player.max_hp)
	player.slot_number = data.get("slot_number", player.slot_number)
	player.battle_scale = data.get("battle_scale", player.battle_scale)
	player.visual_scene = load(data.get("visual_scene", ""))
	player.portrait_texture = load(data.get("portrait_texture", ""))
	
	player.level = data.get("level", player.level)
	player.experience = data.get("experience", player.experience)
	player.xp_to_next_level = data.get("xp_to_next_level", player.xp_to_next_level)
	player.xp_growth_rate = data.get("xp_growth_rate", player.xp_growth_rate)
	
	player.inventory = ResUtil.to_item_array(data.get("inventory", []))
	player.inventory_slots = data.get("inventory_slots", player.inventory_slots)
	
	player.speed = data.get("speed", player.speed)
	player.physical_attack = data.get("physical_attack", player.physical_attack)
	player.physical_defense = data.get("physical_defense", player.physical_defense)
	player.magical_attack = data.get("magical_attack", player.magical_attack)
	player.magical_defense = data.get("magical_defense", player.magical_defense)
	
	player.head_equipment = ResUtil.to_equipment(data.get("head_equipment"))
	player.chest_equipment = ResUtil.to_equipment(data.get("chest_equipment"))
	player.back_equipment = ResUtil.to_equipment(data.get("back_equipment"))
	player.feet_equipment = ResUtil.to_equipment(data.get("feet_equipment"))
	player.hands_equipment = ResUtil.to_equipment(data.get("hands_equipment"))
	player.main_weapon_equipment = ResUtil.to_equipment(data.get("main_weapon_equipment"))
	player.offhand_weapon_equipment = ResUtil.to_equipment(data.get("offhand_weapon_equipment"))
