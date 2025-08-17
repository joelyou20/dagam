extends Resource
class_name EntityResource

@export var portrait_texture: Texture2D

@export var id: String
@export var name: String
@export var description: String
@export var max_hp: int
@export var current_hp: int
@export var slot_number: int
@export var battle_scale: float = 1.0
@export var visual_scene: PackedScene  # Optional: visual prefab for battle

# Experience/Levels
@export var level: int = 1

#Stats
@export var speed: int
@export var physical_attack: int
@export var physical_defense: int
@export var magical_attack: int
@export var magical_defense: int
