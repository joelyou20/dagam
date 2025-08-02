extends Node

@onready var slots: Array[UnitSlot] = []
@onready var player_object: Node3D = $"../../Player" # Adjust type if needed

var player_collision_layer: int
var player_collision_mask: int

func _ready():
	slots = [
		UnitSlot.new(1, $"AllySlots/AllySlot1", UnitSlot.UnitSlotType.ALLY),
		UnitSlot.new(2, $"AllySlots/AllySlot2", UnitSlot.UnitSlotType.ALLY),
		UnitSlot.new(3, $"AllySlots/AllySlot3", UnitSlot.UnitSlotType.ALLY),
		UnitSlot.new(4, $"AllySlots/AllySlot4", UnitSlot.UnitSlotType.ALLY),
		UnitSlot.new(1, $"EnemySlots/EnemySlot1", UnitSlot.UnitSlotType.ENEMY),
		UnitSlot.new(2, $"EnemySlots/EnemySlot2", UnitSlot.UnitSlotType.ENEMY),
		UnitSlot.new(3, $"EnemySlots/EnemySlot3", UnitSlot.UnitSlotType.ENEMY),
		UnitSlot.new(4, $"EnemySlots/EnemySlot4", UnitSlot.UnitSlotType.ENEMY)
	]
	
	call_deferred("_init_battle")
	
func _init_battle():
	BattleManager.place_units(slots)
	start_battle()
	
func start_battle():
	BattleManager.connect("battle_ended", Callable(self, "_on_battle_ended"))
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
