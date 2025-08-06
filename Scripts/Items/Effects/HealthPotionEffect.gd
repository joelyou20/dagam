extends ItemEffect

@export var heal_amount: int = 10

func run():
	PlayerManager.add_hp(heal_amount)

func run_on_unit(unit: Unit):
	unit.current_hp += heal_amount
	print(unit.name + " HP is now " + str(unit.current_hp))
