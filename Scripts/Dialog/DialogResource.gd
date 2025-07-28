# DialogData.gd
extends Resource
class_name DialogResource


@export var npc_id: String
@export var npc_name: String
@export var entries: Array[DialogEntry]
@export var conditions: Array[DialogCondition]
