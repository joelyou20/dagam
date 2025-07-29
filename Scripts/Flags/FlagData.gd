extends Resource
class_name FlagData

enum FlagName {
	UNSET, # Default no flag name value
	KICKED_GREGS_DOG
}

@export var key: FlagName = FlagName.UNSET
@export var value: bool
