extends "res://addons/gut/test.gd"

const QuestTask = preload("res://Scripts/Quests/Tasks/QuestTask.gd")
const QuestResource = preload("res://Scripts/Quests/QuestResource.gd")
const QuestManager = preload("res://Scripts/Managers/QuestManager.gd")

var task: QuestTask
var fake_quest_manager: QuestManagerMock

func before_each():
	task = QuestTask.new()
	fake_quest_manager = QuestManagerMock.new()
	task.quest_manager = fake_quest_manager  # Add this var to your class

func after_each():
	task = null
	await get_tree().process_frame

func test_validate_task_returns_true_when_quest_state_matches():
	var quest := QuestResource.new()
	quest.state = QuestResource.QuestState.ACTIVE

	task.quest_name = QuestData.QuestName.INTRO_QUEST
	task.quest_state = QuestResource.QuestState.ACTIVE
	fake_quest_manager.quests[task.quest_name] = quest

	assert_true(task.validate_task())

func test_validate_task_returns_false_when_state_differs():
	var quest := QuestResource.new()
	quest.state = QuestResource.QuestState.COMPLETED

	task.quest_name = QuestData.QuestName.INTRO_QUEST
	task.quest_state = QuestResource.QuestState.ACTIVE
	fake_quest_manager.quests[task.quest_name] = quest

	assert_false(task.validate_task())

func test_validate_task_returns_false_when_quest_missing():
	fake_quest_manager.quests.clear()

	assert_false(task.validate_task())
