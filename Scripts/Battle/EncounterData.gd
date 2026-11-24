extends Resource
class_name EncounterData

@export var enemies: Array[EnemyResource]
@export var battle_scene_path: String

# Preconstructed Hex deck used by this encounter. Legacy scene paths remain loadable data.
@export var hex_deck_id: String = "thornbound"
