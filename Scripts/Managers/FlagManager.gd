extends Node

var flags := preload("res://Resources/flags.tres")

func set_flag(flag_name: FlagData.FlagName, value: bool = true):
	for flag in flags.flags:
		if flag.key == flag_name:
			flag.value = value
			return

func is_flag_set(flag_name: FlagData.FlagName) -> bool:
	return flags.flags[flag_name].value

func get_flag(flag_name: FlagData.FlagName) -> FlagData:
	for flag in flags.flags:
		if flag.key == flag_name:
			return flag
	return null

func toggle_flag(flag_name: FlagData.FlagName):
	set_flag(flag_name, !is_flag_set(flag_name))

func save_flags():
	var save_data = flags.flags
	var file = FileAccess.open("user://save_flags.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))

func load_flags():
	if FileAccess.file_exists("user://save_flags.json"):
		flags.flags = FileAccess.open("user://save_flags.json", FileAccess.READ).get_as_json()
