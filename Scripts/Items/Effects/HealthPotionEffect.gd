extends ItemEffect

@export var heal_amount: int = 10

func run():
	PlayerManager.add_hp(heal_amount)
