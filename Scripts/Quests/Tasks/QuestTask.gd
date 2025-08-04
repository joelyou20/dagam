extends Task
class_name QuestTask

@export var quest_name: QuestData.QuestName
@export var quest_state: QuestResource.QuestState

var quest_manager: QuestManager

func validate_task() -> bool:
	if quest_manager == null:
		quest_manager = QuestManager

	var quest = quest_manager.get_quest(quest_name)
	return quest != null and quest.state == quest_state
