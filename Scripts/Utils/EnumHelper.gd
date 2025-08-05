extends Node
class_name EnumHelper

## Get the name (string) of an enum value
static func get_name_as_string(enum_dict: Dictionary, value: int) -> String:
	if value >= 0 and value < enum_dict.size():
		return enum_dict.keys()[value]
	return ""

## Get the value (int) from a name
static func get_value(enum_dict: Dictionary, name: String) -> int:
	if enum_dict.has(name):
		return enum_dict[name]
	return -1

## Get all enum names
static func get_names(enum_dict: Dictionary) -> Array[String]:
	return enum_dict.keys()

## Get all enum values
static func get_values(enum_dict: Dictionary) -> Array[int]:
	return enum_dict.values()
