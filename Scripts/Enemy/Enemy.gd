extends Area3D
class_name Enemy

@export var encounter: EncounterData

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if body.is_in_group("Player"):
		InteractionHandler.block("Enemy")
		BattleManager.build_battle_from_encounter(encounter)
		SceneManager.load_scene(encounter.battle_scene_path, true, true, "", 0.1)
		await SceneManager.fade_layer.fade_completed
		queue_free()  # optional: despawn this enemy in the world
		InteractionHandler.unblock("Enemy")
