extends Resource
class_name FlagData

enum FlagName {
	UNSET, # Default no flag name value
	KICKED_GREGS_DOG,
	READY_TO_KICK_AGAIN
}

@export var key: FlagName = FlagName.UNSET
@export var value: bool
