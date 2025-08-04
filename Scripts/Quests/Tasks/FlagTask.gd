extends Task
class_name FlagTask

@export var flag: FlagData

var flag_manager : FlagManager

func validate_task():
	if flag_manager == null:
		flag_manager = FlagManager
		
	var result: bool = true

	var flag_get_result = flag_manager.get_flag(flag.key)
	if not flag_get_result or flag_get_result.value != flag.value:
		result = false
		
	return result
