extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# TODO basic MVP AI to start
func take_turn(unit: Unit) -> void:
	if (!unit):
		return
	
	InteractionHandler.block("EnemyTurn")
	if (unit.type == Unit.UnitType.ENEMY):
		var ally: Unit = UnitManager.ally_units[0]
		ally.take_damage(unit.resource.physical_attack)
	InteractionHandler.unblock("EnemyTurn")
	print("Turn completed: %s" % unit.resource.name)
	return
