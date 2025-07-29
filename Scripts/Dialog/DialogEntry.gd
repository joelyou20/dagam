# DialogData.gd
extends Resource
class_name DialogEntry

@export var id: String
@export var text: Array[String]
@export var state: DialogState.State = DialogState.State.PENDING
@export var options: Array[DialogOption]
@export var flags: Array[FlagData.FlagName]
