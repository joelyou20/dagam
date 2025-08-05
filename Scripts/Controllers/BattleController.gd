extends Node

func _ready():
	# Get all nodes and explicitly type the result
	var unit_slot_nodes: Array[UnitSlot] = []
	var all_nodes = get_tree().get_nodes_in_group("unit_slots")
	
	for node in all_nodes:
		if node is UnitSlot:
			unit_slot_nodes.append(node as UnitSlot)
	
	call_deferred("_init_battle", unit_slot_nodes)

func _init_battle(slots: Array[UnitSlot]):
	BattleManager.place_units(slots)
	
	# NOTE: Uncomment to debug unit slots
	# Get all unit slots and debug them
	#var all_nodes = get_tree().get_nodes_in_group("unit_slots")
	#for slot in all_nodes:
		#if slot.has_method("debug_slot"):
			#slot.debug_slot()
			
	start_battle()

func start_battle():
	BattleManager.begin_battle()
