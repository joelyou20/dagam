extends Resource
class_name BattleAction

enum ActionType {
	ATTACK,
	SKILL,
	ITEM,
	FLEE
}

var _source_slot: int
var _action_type: ActionType
var _item: ItemResource = null

func _init(source_slot: int, action_type: ActionType):
	_source_slot = source_slot
	_action_type = action_type

func get_source_slot() -> int:
	return _source_slot

func get_action_type() -> ActionType:
	return _action_type

# --- Item-specific methods ---
func set_item(item: ItemResource):
	_item = item

func get_item() -> ItemResource:
	return _item
