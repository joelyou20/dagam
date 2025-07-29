# DialogEntry.gd
extends Resource
class_name DialogCondition

enum ConditionLogic {
	IF_ANY,
	IF_ALL,
	IF_NONE
}

@export var flags: Array[FlagData.FlagName]
@export var active_quests: Array[QuestData.QuestName]
@export var flag_logic: ConditionLogic = ConditionLogic.IF_ANY #References flags
@export var quest_logic: ConditionLogic = ConditionLogic.IF_ANY #References flags
@export var next: String
@export var priority: int
