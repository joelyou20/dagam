class_name QuestData
extends Resource

enum QuestName { UNSET, INTRO_QUEST, ANOTHER_DOG_TO_KICK, MEADOW_ENCORE }

@export var name: QuestName = QuestName.UNSET
