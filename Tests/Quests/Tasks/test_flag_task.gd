extends "res://addons/gut/test.gd"

var task: FlagTask
var fake_flag_manager: FlagManagerMock

func before_each():
	task = FlagTask.new()
	fake_flag_manager = FlagManagerMock.new()
	task.flag_manager = fake_flag_manager

func after_each():
	task = null
	await get_tree().process_frame

func test_validate_task_returns_true_when_flag_matches():
	var data := FlagData.new()
	data.key = FlagData.FlagName.UNSET
	data.value = true
	task.flag = data

	task.flag_manager.set_flag(data.key, data.value)

	assert_true(task.validate_task())

func test_validate_task_returns_false_when_flag_value_differs():
	var task_flag := FlagData.new()
	task_flag.key = FlagData.FlagName.UNSET
	task_flag.value = true
	task.flag = task_flag

	var world_flag := FlagData.new()
	world_flag.key = FlagData.FlagName.UNSET
	world_flag.value = false
	task.flag_manager.set_flag(world_flag.key, world_flag.value)

	assert_false(task.validate_task())

func test_validate_task_returns_false_when_flag_missing():
	var task_flag := FlagData.new()
	task_flag.key = FlagData.FlagName.UNSET
	task_flag.value = true
	task.flag = task_flag

	task.flag_manager.queue_free()  # No flags set

	assert_false(task.validate_task())
