extends OnAttackEffectEquipmentModifier
class_name InstaKillOnAttackEquipmentModifier

func run(target_unit: Unit = null):
	target_unit.die()
	print(target_unit.name + " has been instantly killed by " + self.resource_path )
