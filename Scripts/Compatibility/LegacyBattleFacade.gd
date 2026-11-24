extends Node
## Parse-time compatibility for retained RPG scene resources; no combat is executed.

# Legacy scene properties remain harmless while old resources are migrated.
var battle_ui = null
var is_targeting_mode := false
var pending_action = null


func start_targeting(_action) -> void:
	pass


func end_targeting() -> void:
	pass


func select_target(_target) -> void:
	pass


func execute_action(_action, _target) -> void:
	pass
