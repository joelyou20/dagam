class_name FlagData
extends Resource

enum FlagName {
	UNSET,
	KICKED_GREGS_DOG,
	READY_TO_KICK_AGAIN,
	OPENED_DOOR,
	MEADOW_MET_LIORA,
	MEADOW_INVITED_ROWAN,
	MEADOW_ENCORE_FINISHED
}

@export var key: FlagName = FlagName.UNSET
@export var value: bool
