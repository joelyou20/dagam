extends FlagManager
class_name FlagManagerMock

var test_flags: Array[FlagData]

func _init():
	test_flags = preload("res://Resources/flags.tres").duplicate(true).flags  # Deep copy

# Set a flag by key
func set_flag(flag_name: FlagData.FlagName, value: bool = true):
	for flag in test_flags:
		if flag.key == flag_name:
			flag.value = value
			return

# Get the full FlagData object (if needed)
func get_flag(flag_name: FlagData.FlagName) -> FlagData:
	for flag in test_flags:
		if flag.key == flag_name:
			return flag
	return null
	
# Get whether a flag is set
func is_flag_set(flag_name: FlagData.FlagName) -> bool:
	for flag in test_flags:
		if flag.key == flag_name:
			return flag.value
	return false
