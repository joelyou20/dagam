extends Task
class_name QuestTask

@export var quest_name: QuestData.QuestName
@export var quest_state: QuestResource.QuestState

func validate_task():
	var result: bool = true
	
	if QuestManager.get_quest(quest_name).state != quest_state:
		result = false
		
	return result
