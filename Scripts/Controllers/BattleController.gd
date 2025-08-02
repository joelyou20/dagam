extends Node

@onready var ally_slots: Array[UnitSlot] = []
@onready var enemy_slots: Array[UnitSlot] = []
@onready var player_object: Node3D = $"../../Player" # Adjust type if needed

var player_collision_layer: int
var player_collision_mask: int

func _ready():
	ally_slots = [
		UnitSlot.new(1, $"AllySlots/AllySlot1"),
		UnitSlot.new(2, $"AllySlots/AllySlot2"),
		UnitSlot.new(3, $"AllySlots/AllySlot3"),
		UnitSlot.new(4, $"AllySlots/AllySlot4")
	]

	enemy_slots = [
		UnitSlot.new(1, $"EnemySlots/EnemySlot1"),
		UnitSlot.new(2, $"EnemySlots/EnemySlot2"),
		UnitSlot.new(3, $"EnemySlots/EnemySlot3"),
		UnitSlot.new(4, $"EnemySlots/EnemySlot4")
	]
	
	call_deferred("_init_battle")
	
func _init_battle():
	place_ally_units()
	place_enemy_units()
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

func place_ally_units():
	for slot in ally_slots:
		BattleManager.place_ally(slot)
		
func place_enemy_units():
	for slot in enemy_slots:
		BattleManager.place_enemy(slot)
