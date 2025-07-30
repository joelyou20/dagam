# DialogEntry.gd
extends Resource
class_name DialogCondition

enum ConditionLogic {
	IF_ANY,
	IF_ALL,
	IF_NONE
}

@export var tasks: Array[Task]
@export var logic: ConditionLogic = ConditionLogic.IF_ANY
@export var next: String
@export var priority: int
