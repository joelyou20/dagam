extends Resource
class_name PlayerData

@export var name: String = "Hero"
@export var level: int = 1
@export var speed: int
@export var experience: int = 0
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var attack_power: int
@export var inventory: Array[ItemResource] = []
@export var visual_scene: PackedScene
@export var slot_number: int = 1
