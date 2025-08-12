# Unit.gd
extends Node
class_name Unit

enum UnitType {
	PLAYER,
	ALLY,
	ENEMY
}

var resource: EntityResource
var type: UnitType
var is_player_controlled: bool = false
var is_alive: bool = true

func take_damage(amount: int):
	resource.current_hp = max(resource.current_hp - amount, 0)
	if resource.current_hp <= 0:
		die()

func die():
	is_alive = false
	resource.current_hp = 0
	print(resource.name, " has fallen.")

	var slot = get_parent()
	if slot and slot is UnitSlot:
		# Remove Sprite3D from the slot
		for child in slot.get_children():
			if child is Sprite3D:
				child.queue_free()
		
		# Clear the unit reference
		slot.unit = null

	# Now remove the Unit itself
	queue_free()
