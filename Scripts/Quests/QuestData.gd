extends Resource
class_name QuestData

enum QuestName {
	UNSET, # Default no flag name value
	INTRO_QUEST,
	ANOTHER_DOG_TO_KICK
}

@export var name: QuestName = QuestName.UNSET
