extends Node3D
class_name Enemy

@export var encounter: EncounterData

@onready var area := $Area3D

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if body.is_in_group("Player"):
		BattleManager.build_battle_from_encounter(encounter)
		SceneManager.transition_to_scene(encounter.battle_scene_path)
		queue_free()  # optional: despawn this enemy in the world
