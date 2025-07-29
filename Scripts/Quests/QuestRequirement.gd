extends Resource
class_name QuestRequirement

@export var flags: Array[FlagData.FlagName]
@export var tasks: Array[Task]

func validate_requirements():
	var requirements_met: bool = true
	for flag in flags:
		if !FlagManager.is_flag_set(flag):
			requirements_met = false
	
	for task in tasks:
		if !task.validate_task():
			requirements_met = false
	
	return requirements_met
