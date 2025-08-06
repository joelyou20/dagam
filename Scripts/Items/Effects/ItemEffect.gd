extends Object
class_name ItemEffect

func run():
	push_error("ItemEffect.run() not implemented!")

func run_on_unit(unit: Unit):
	push_warning("ItemEffect.run_on_unit() called — override in your script.")
