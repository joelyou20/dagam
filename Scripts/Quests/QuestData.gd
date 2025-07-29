extends Resource
class_name QuestData

enum QuestName {
	UNSET, # Default no flag name value
	INTRO_QUEST
}

@export var name: QuestName = QuestName.UNSET
