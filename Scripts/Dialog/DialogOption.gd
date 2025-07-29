# DialogEntry.gd
extends Resource
class_name DialogOption

@export var text: String
@export var next: String
@export var flags: Array[FlagData.FlagName]
@export var accepted_quest: QuestData.QuestName
