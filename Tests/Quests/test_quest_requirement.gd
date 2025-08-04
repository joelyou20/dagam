extends "res://addons/gut/test.gd"

class FakeTaskSuccess:
	extends Task

	func validate_task() -> bool:
		return true

class FakeTaskFail:
	extends Task

	func validate_task() -> bool:
		return false

var requirement: QuestRequirement
var fake_flag_manager: FlagManagerMock

func before_each():
	requirement = QuestRequirement.new()
	fake_flag_manager = FlagManagerMock.new()
	requirement.flag_manager = fake_flag_manager

func after_each():
	requirement = null
	await get_tree().process_frame

func test_validate_with_all_flags_and_tasks_success():
	requirement.flags = [FlagData.FlagName.UNSET, FlagData.FlagName.KICKED_GREGS_DOG]
	
	for flag in requirement.flags:
		fake_flag_manager.set_flag(flag)
		
	requirement.tasks = [FakeTaskSuccess.new(), FakeTaskSuccess.new()]

	assert_true(requirement.validate_requirements())

func test_validate_fails_when_flag_missing():
	requirement.flags = [FlagData.FlagName.UNSET]
	fake_flag_manager.test_flags = []  # Empty: no flags set
	requirement.tasks = [FakeTaskSuccess.new()]

	assert_false(requirement.validate_requirements())

func test_validate_fails_when_task_invalid():
	requirement.flags = []
	fake_flag_manager.test_flags = []
	requirement.tasks = [FakeTaskFail.new()]

	assert_false(requirement.validate_requirements())

func test_validate_fails_when_both_invalid():
	requirement.flags = [FlagData.FlagName.UNSET]
	fake_flag_manager.test_flags = []
	requirement.tasks = [FakeTaskFail.new()]

	assert_false(requirement.validate_requirements())
