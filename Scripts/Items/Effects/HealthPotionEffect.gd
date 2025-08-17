extends ItemEffect

@export var heal_amount: int = 10

# Return true if item usage was successful
func run(target_resource: EntityResource = null) -> bool:
	if target_resource != null:
		var new_hp = target_resource.current_hp + heal_amount
		if new_hp <= target_resource.max_hp:
			target_resource.current_hp = clamp(new_hp, 0, target_resource.max_hp)
			print(target_resource.name + " HP is now " + str(target_resource.current_hp))
			return true
		else:
			print(target_resource.name + " HP is already full. Skipping potion.")
	
	return false
