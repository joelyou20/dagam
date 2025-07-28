extends Node

var flags := preload("res://Resources/flags.tres")

func set_flag(flag_name: String, value: bool = true):
	flags.flags[flag_name] = value

func is_flag_set(flag_name: String) -> bool:
	return flags.flags.get(flag_name, false)
	
func toggle_flag(flag_name: String):
	flags.flags[flag_name] = !is_flag_set(flag_name)
	print("flag toggled: " + flag_name)
	print(is_flag_set(flag_name))
	
func save_flags():
	var save_data = flags.flags
	var file = FileAccess.open("user://save_flags.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))

func load_flags():
	if FileAccess.file_exists("user://save_flags.json"):
		flags.flags = FileAccess.open("user://save_flags.json", FileAccess.READ).get_as_json()
