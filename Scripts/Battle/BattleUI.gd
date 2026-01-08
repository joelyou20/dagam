extends UIBase
class_name BattleUI

@onready var EnemyUIEntryScene := preload("res://Scenes/UI/Battle/EnemyUIEntry.tscn")
@onready var battle_items_ui_scene := preload("res://Scenes/UI/Battle/BattleItemsUI.tscn")
@onready var ally_info_scene := preload("res://Scenes/UI/Battle/AllyBattleInfo.tscn")

@onready var enemies_container: VBoxContainer = $Panel/EnemiesContainer
@onready var allies_container: GridContainer = $Panel/AlliesContainer
@onready var attack_button: Button = $Panel/GridContainer/AttackButton
@onready var skills_button: Button = $Panel/GridContainer/SkillsButton
@onready var items_button: Button = $Panel/GridContainer/ItemsButton
@onready var flee_button: Button = $Panel/GridContainer/FleeButton
@onready var turn_order_ui: TurnOrderUI = $TurnOrderUI

var battle_items_ui: BattleItemsUI = null
var _unit_Manager: UnitManager

func _ready():
	_unit_Manager = UnitManager
	
	# Connect buttons
	attack_button.pressed.connect(on_attack_pressed)
	attack_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	skills_button.pressed.connect(on_skills_pressed)
	skills_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	items_button.pressed.connect(on_items_pressed)
	items_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	flee_button.pressed.connect(on_flee_pressed)
	flee_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	_unit_Manager.active_unit_changed.connect(set_active_unit)
	
	turn_order_ui.update_ui.call_deferred()
	
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE and BattleManager.is_targeting_mode:
			BattleManager.end_targeting()
			print("Targeting cancelled")
			
func on_attack_pressed():
	hide_battle_items_ui()
	var source_slot: int = _unit_Manager.get_active_unit_slot()
	var action = BattleAction.new(source_slot, BattleAction.ActionType.ATTACK)
	BattleManager.start_targeting(action)

func on_skills_pressed():
	hide_battle_items_ui()
	print("Skills selected")
	# e.g., BattleManager.show_skills_menu()

func on_items_pressed():
	print("Items selected")
	
	# Show inventory popup
	show_battle_items_ui()
	
func on_flee_pressed():
	hide_battle_items_ui()
	print("Flee selected")
	BattleManager.attempt_to_flee()

func show_battle_items_ui():
	# Remove an existing selector if open
	if battle_items_ui and is_instance_valid(battle_items_ui):
		hide_battle_items_ui()

	# Instance the UI
	battle_items_ui = battle_items_ui_scene.instantiate() as BattleItemsUI
	add_child(battle_items_ui)

	# Fill the UI with items
	battle_items_ui.update_ui()

	# Hook up item click → callback
	for slot in battle_items_ui.vbox_container.get_children():
		if slot.has_signal("slot_clicked"):
			slot.slot_clicked.connect(func():
				hide_battle_items_ui()
			)
			
func hide_battle_items_ui():
	if battle_items_ui:
		battle_items_ui.queue_free()
		battle_items_ui = null

func populate_enemies(units: Array[Unit]):
	# Clear all children at once
	for child in enemies_container.get_children():
		child.queue_free()
	
	# Group enemies and create entries in a single loop
	var enemy_groups: Dictionary = {}
	for unit in units:
		var enemy_name = unit.resource.name
		if not enemy_groups.has(enemy_name):
			# First occurrence - create the entry
			var entry = EnemyUIEntryScene.instantiate() as EnemyUIEntry
			entry.initialize(unit, 1)
			enemies_container.add_child(entry)
			enemy_groups[enemy_name] = entry
		else:
			# Additional occurrence - update the count
			var existing_entry = enemy_groups[enemy_name] as EnemyUIEntry
			existing_entry.increment_count()  # Assumes you have a count property and update_count method

func populate_ally_info_container(units: Array[Unit]) -> void:
	# Clear previous entries
	for child in allies_container.get_children():
		child.queue_free()

	# Grid spacing (instead of "separation")
	allies_container.add_theme_constant_override("hseparation", 12) # horizontal gap
	allies_container.add_theme_constant_override("vseparation", 12) # vertical gap

	# Add each ally
	for unit: Unit in units:
		var ally_info := ally_info_scene.instantiate() as Control
		ally_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ally_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
		ally_info.custom_minimum_size = Vector2(120, 36)  # ensures consistent cell size
		allies_container.add_child(ally_info)
		ally_info.call_deferred("update_ally_info", unit)

	allies_container.queue_sort()
	
func set_active_unit(u: Unit):
	turn_order_ui.turn_order_changed.emit()
