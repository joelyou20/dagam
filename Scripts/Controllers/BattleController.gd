extends Node

@onready var player_object: Node3D = $"../../Player"
var slots: Array[UnitSlot] = []

var player_collision_layer: int
var player_collision_mask: int

func _ready():
	BattleManager.connect("battle_ended", Callable(self, "_on_battle_ended"))
	
	# Get all nodes and explicitly type the result
	var unit_slot_nodes: Array[UnitSlot] = []
	var all_nodes = get_tree().get_nodes_in_group("unit_slots")
	
	for node in all_nodes:
		if node is UnitSlot:
			unit_slot_nodes.append(node as UnitSlot)
	
	slots = unit_slot_nodes
	call_deferred("_init_battle")

func _init_battle():
	BattleManager.place_units(slots)
	
	var all_nodes = get_tree().get_nodes_in_group("unit_slots")
	
	# NOTE: Uncomment to debug unit slots
	# Get all unit slots and debug them
	#for slot in all_nodes:
		#if slot.has_method("debug_slot"):
			#slot.debug_slot()
			
	start_battle()

func start_battle():
	player_collision_layer = player_object.collision_layer
	player_collision_mask = player_object.collision_mask
	_disable_overworld_player()
	BattleManager.begin_battle()

func _on_battle_ended():
	BattleManager.disconnect("battle_ended", Callable(self, "_on_battle_ended"))
	_enable_overworld_player()
	get_tree().change_scene_to_file("res://Scenes/World.tscn")

func _disable_overworld_player():
	player_object.visible = false
	player_object.set_process(false)
	player_object.set_physics_process(false)
	player_object.set_collision_layer(0)
	player_object.set_collision_mask(0)

func _enable_overworld_player():
	player_object.visible = true
	player_object.set_process(true)
	player_object.set_physics_process(true)
	player_object.set_collision_layer(player_collision_layer)
	player_object.set_collision_mask(player_collision_mask)
