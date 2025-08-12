extends ItemEffect

@export var heal_amount: int = 10

func run(target_resource: EntityResource = null):
	PlayerManager.add_hp(heal_amount)
	if target_resource != null:
		target_resource.current_hp += heal_amount
		print(target_resource.name + " HP is now " + str(target_resource.current_hp))
