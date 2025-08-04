extends QuestManager
class_name QuestManagerMock

var quests: Dictionary = {}

func get_quest(name: QuestData.QuestName) -> QuestResource:
	return quests.get(name, null)
