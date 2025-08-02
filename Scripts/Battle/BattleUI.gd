extends UIBase
class_name BattleUI

@onready var attack_button: Button = $Panel/GridContainer/AttackButton
@onready var skills_button: Button = $Panel/GridContainer/SkillsButton
@onready var items_button: Button = $Panel/GridContainer/ItemsButton
@onready var flee_button: Button = $Panel/GridContainer/FleeButton

func _ready():
	# Connect buttons
	attack_button.pressed.connect(on_attack_pressed)
	skills_button.pressed.connect(on_skills_pressed)
	items_button.pressed.connect(on_items_pressed)
	flee_button.pressed.connect(on_flee_pressed)
	
func on_attack_pressed():
	print("Attack selected")
	# Call BattleManager to begin attack target selection
	# e.g., BattleManager.select_attack_target()

func on_skills_pressed():
	print("Skills selected")
	# e.g., BattleManager.show_skills_menu()

func on_items_pressed():
	print("Items selected")
	# e.g., InventoryManager.show_inventory_ui_in_battle()

func on_flee_pressed():
	print("Flee selected")
	# e.g., BattleManager.attempt_flee()
