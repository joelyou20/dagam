extends Node

@export var flags := preload("res://Resources/flags.tres")  # Array of FlagData

# Set a flag by key
func set_flag(flag_name: FlagData.FlagName, value: bool = true):
	for flag in flags.flags:
		if flag.key == flag_name:
			flag.value = value
			return

# Get whether a flag is set
func is_flag_set(flag_name: FlagData.FlagName) -> bool:
	for flag in flags.flags:
		if flag.key == flag_name:
			return flag.value
	return false

# Toggle a flag's value
func toggle_flag(flag_name: FlagData.FlagName):
	set_flag(flag_name, !is_flag_set(flag_name))

# Get the full FlagData object (if needed)
func get_flag(flag_name: FlagData.FlagName) -> FlagData:
	for flag in flags.flags:
		if flag.key == flag_name:
			return flag
	return null

# Save all flags as a Dictionary { "flag_key": true/false }
func save_flags() -> Dictionary:
	var result := {}
	for flag in flags.flags:
		result[str(flag.key)] = flag.value
	return result

# Load flag values from a Dictionary
func load_flags(data: Dictionary):
	for flag in flags.flags:
		if data.has(str(flag.key)):
			flag.value = data[str(flag.key)]

# Optional: Check if a flag exists
func has_flag(flag_name: FlagData.FlagName) -> bool:
	for flag in flags.flags:
		if flag.key == flag_name:
			return true
	return false
