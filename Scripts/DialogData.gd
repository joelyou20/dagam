# DialogueData.gd
extends Resource
class_name DialogueData

@export var npc_id: String
@export var npc_name: String
@export var state: String = "default"
@export var entries: Array[Dictionary] = []
