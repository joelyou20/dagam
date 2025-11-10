extends StaticEffectEquipmentModifier
class_name OnFleeStaticModifier

@export var flee_chance: float = 100.0

func run():
	if (BattleManager.current_battle_data):
		BattleManager.current_battle_data.flee_chance = flee_chance
	print("Flee chance is modified to: " + str(BattleManager.current_battle_data.flee_chance))
	
