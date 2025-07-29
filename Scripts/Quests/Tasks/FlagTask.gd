extends Task
class_name FlagTask

@export var flag: FlagData

func validate_task():
	var result: bool = true

	if FlagManager.get_flag(flag.key).value != flag.value:
		result = false
		
	return result
