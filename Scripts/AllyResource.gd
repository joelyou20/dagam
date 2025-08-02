# AllyResource.gd
extends Resource
class_name AllyResource

@export var id: String
@export var name: String
@export var max_hp: int
@export var speed: int
@export var attack_power: int
@export var slot_number: int
@export var visual_scene: PackedScene  # Optional: visual prefab for battle
