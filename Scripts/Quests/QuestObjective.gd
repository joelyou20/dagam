class_name QuestObjective
extends Resource

@export var id: String
@export var flag: String

@export var description: String = ""

func is_complete() -> bool:
	var key = FlagData.FlagName.get(flag)

	return key != null and FlagManager.is_flag_set(key)
