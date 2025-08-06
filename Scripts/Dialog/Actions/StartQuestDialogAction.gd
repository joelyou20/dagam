extends DialogAction
class_name StartQuestDialogAction

@export var quest_name: QuestData.QuestName

func execute():
	if quest_name != null:
		QuestManager.accept_quest(quest_name)
