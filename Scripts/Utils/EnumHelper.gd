extends Node

func enum_to_string(enum_type: Dictionary, value: int) -> String:
	for name in enum_type.keys():
		if enum_type[name] == value:
			return name
	return "UNKNOWN"
