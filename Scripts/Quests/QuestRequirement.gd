extends Resource
class_name QuestRequirement

@export var flags: Array[FlagData.FlagName]

func validate_requirements():
	var requirements_met: bool = true
	for flag in flags:
		var flag_name = FlagData.FlagName.keys()[flag]
		if !FlagManager.is_flag_set(flag_name):
			requirements_met = false
