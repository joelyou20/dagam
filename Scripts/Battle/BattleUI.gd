extends UIBase
class_name BattleUI

@onready var EnemyUIEntryScene := preload("res://Scenes/UI/Battle/EnemyUIEntry.tscn")
@onready var battle_items_ui_scene := preload("res://Scenes/UI/Battle/BattleItemsUI.tscn")

@onready var enemies_container: VBoxContainer = $Panel/EnemiesContainer
@onready var allies_container: VBoxContainer = $Panel/AlliesContainer
@onready var attack_button: Button = $Panel/GridContainer/AttackButton
@onready var skills_button: Button = $Panel/GridContainer/SkillsButton
@onready var items_button: Button = $Panel/GridContainer/ItemsButton
@onready var flee_button: Button = $Panel/GridContainer/FleeButton

var battle_items_ui: BattleItemsUI = null

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
	
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE and BattleManager.is_targeting_mode:
			BattleManager.end_targeting()
			print("Targeting cancelled")
			
func on_attack_pressed():
	var source_slot: int = BattleManager.get_active_unit_slot()
	var action = BattleAction.new(source_slot, BattleAction.ActionType.ATTACK)
	BattleManager.start_targeting(action)

func on_skills_pressed():
	print("Skills selected")
	# e.g., BattleManager.show_skills_menu()

func on_items_pressed():
	print("Items selected")
	var items: Array[InventorySlotData] = InventoryManager.get_usable_items()
	
	# Show inventory popup
	show_item_selector(items, _on_item_selected)

func _on_item_selected(item: ItemResource):
	print("Selected item: ", item.name)

	#if item.requires_target:
		#pending_action = BattleAction.new_from_item(item)
		#is_targeting_mode = true
		# maybe show: "Select a target"
	#else:
		# Apply immediately
		#item.effect_script.run()  # or however you determine self-target
	InventoryManager.use_item(item)
	InventoryManager.remove_item(item, 1)
	
func on_flee_pressed():
	print("Flee selected")
	BattleManager.attempt_to_flee()
	
func show_item_selector(items: Array[InventorySlotData], callback: Callable):
	# Remove an existing selector if open
	if battle_items_ui and is_instance_valid(battle_items_ui):
		battle_items_ui.queue_free()
		battle_items_ui = null

	# Instance the UI
	battle_items_ui = battle_items_ui_scene.instantiate() as BattleItemsUI
	add_child(battle_items_ui)

	# Fill the UI with items
	battle_items_ui.populate_items(items)

	# Hook up item click → callback
	for slot in battle_items_ui.vbox_container.get_children():
		if slot.has_signal("slot_clicked"):
			slot.slot_clicked.connect(func(inventory_slot):
				if callback:
					callback.call(inventory_slot.get_item())
				# Optionally close the UI after selection
				#battle_items_ui.queue_free()
				#battle_items_ui = null
			)

func populate_enemies(units: Array[Unit]):
	# Clear all children at once
	for child in enemies_container.get_children():
		child.queue_free()
	
	# Group enemies and create entries in a single loop
	var enemy_groups: Dictionary = {}
	for unit in units:
		var enemy_name = unit.title
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
		
