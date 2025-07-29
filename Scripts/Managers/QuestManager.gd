extends Node

const questResource = preload("res://Scripts/Quests/QuestResource.gd")

var active_quests: Dictionary = {}  # quest_id -> QuestResource
var completed_quests: Array[String] = []

func accept_quest(quest_name: QuestData.QuestName):
	var quest : QuestResource = get_quest(quest_name)

	if quest == null or quest.id in active_quests:
		return

	active_quests[quest.id] = quest
	quest.state = QuestResource.QuestState.ACTIVE
	print("Quest started: %s" % quest.title)

func complete_quest(quest_id: String):
	if not active_quests.has(quest_id):
		return
	var quest: QuestResource = active_quests[quest_id]
	quest.state = QuestResource.QuestState.COMPLETED
	completed_quests.append(quest_id)
	print("Quest completed: %s" % quest.title)

func get_quest(quest_enum: QuestData.QuestName) -> QuestResource:
	var quest_name : String = QuestData.QuestName.keys()[quest_enum]
	var path := "res://Resources/Quests/%s.tres" % quest_name
	var quest = load(path)
	if quest == null:
		push_error("Quest not found at path: %s" % path)
	return quest

func is_quest_active(quest: QuestData.QuestName) -> bool:
	var quest_id : String = QuestData.QuestName.keys()[quest]
	var result: bool = active_quests.has(quest_id)
	return result

# TODO
func validate_active_quest_objectives():
	for quest_id in active_quests.keys():
		var quest: QuestResource = active_quests[quest_id]
		for requirement in quest.requirements:
			if requirement.validate_requirements() and not completed_quests.has(quest_id):
				complete_quest(quest_id)

# TODO
func validate_locked_quest_requirements():
	for quest_id in active_quests.keys():
		var quest: QuestResource = active_quests[quest_id]
		for requirement in quest.requirements:
			if requirement.validate_requirements() and not completed_quests.has(quest_id):
				complete_quest(quest_id)

func validate_active_quest_requirements():
	for quest_id in active_quests.keys():
		var quest: QuestResource = active_quests[quest_id]
		for requirement in quest.requirements:
			if requirement.validate_requirements() and not completed_quests.has(quest_id):
				complete_quest(quest_id)
