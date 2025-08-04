# Unit.gd
extends Node
class_name Unit

enum UnitType {
	PLAYER,
	ALLY,
	ENEMY
}

@export var id: String
@export var title: String
@export var max_hp: int
@export var current_hp: int
@export var speed: int
@export var attack_power: int
@export var type: UnitType
@export var visual_scene: PackedScene
@export var slot_number: int
@export var battle_scale: float = 1.0

var is_player_controlled: bool = false
var is_alive: bool = true

func take_damage(amount: int):
	current_hp = max(current_hp - amount, 0)
	if current_hp <= 0:
		die()

func die():
	is_alive = false
	current_hp = 0
	print(title, " has fallen.")

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
