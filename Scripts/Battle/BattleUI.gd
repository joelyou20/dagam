extends UIBase
class_name BattleUI

@onready var EnemyUIEntryScene := preload("res://Scenes/UI/Battle/EnemyUIEntry.tscn")

@onready var enemies_container: VBoxContainer = $Panel/EnemiesContainer
@onready var allies_container: VBoxContainer = $Panel/AlliesContainer
@onready var attack_button: Button = $Panel/GridContainer/AttackButton
@onready var skills_button: Button = $Panel/GridContainer/SkillsButton
@onready var items_button: Button = $Panel/GridContainer/ItemsButton
@onready var flee_button: Button = $Panel/GridContainer/FleeButton

func _ready():
	# Connect buttons
	attack_button.pressed.connect(on_attack_pressed)
	attack_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	skills_button.pressed.connect(on_skills_pressed)
	skills_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	items_button.pressed.connect(on_items_pressed)
	items_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	flee_button.pressed.connect(on_flee_pressed)
	flee_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
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

func populate_enemies(units: Array[Unit]):
	for child in enemies_container.get_children():
		child.queue_free()
	for i in units.size():
		var unit = units[i]
		var entry = EnemyUIEntryScene.instantiate() as EnemyUIEntry
		entry.initialize(unit, i)
		entry.enemy_selected.connect(_on_enemy_selected)
		enemies_container.add_child(entry)
		
func _on_enemy_selected(unit: Unit):
	print("Selected enemy:", unit.title)
	BattleManager.select_target(unit)
