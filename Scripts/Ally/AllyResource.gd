# AllyResource.gd
extends Resource
class_name AllyResource

@export var id: String
@export var name: String
@export var max_hp: int
@export var current_hp: int
@export var speed: int
@export var attack_power: int
@export var slot_number: int
@export var battle_scale: float = 1.0
@export var visual_scene: PackedScene  # Optional: visual prefab for battle
@export var portrait_texture: Texture2D

# Experience/Levels
@export var level: int = 1
@export var experience: int = 0
@export var xp_to_next_level: int = 100
@export var xp_growth_rate: float = 1.2  # How much XP requirement grows per level
