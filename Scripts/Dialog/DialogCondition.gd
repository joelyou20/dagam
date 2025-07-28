# DialogEntry.gd
extends Resource
class_name DialogCondition

enum ConditionLogic {
	IF_ANY,
	IF_ALL,
	IF_NONE
}

@export var flags: Array[String]
@export var logic: ConditionLogic = ConditionLogic.IF_ANY #References flags
@export var next: String
