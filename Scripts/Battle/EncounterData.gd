extends Resource
class_name EncounterData

@export var enemies: Array[EnemyResource]
@export var battle_scene_path: String

# Preconstructed Hex deck used by this encounter. Legacy scene paths remain loadable data.
@export var hex_deck_id: String = "thornbound"

## Mirrored natural terrain. It affects compatibility but starts at level zero.
@export var hex_terrains: Array[String] = ["Earth", "Sky", "Fire", "Water", "Dark", "Light"]
@export var locked_hexes: Array[int] = []
