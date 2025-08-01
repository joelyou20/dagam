extends Node

@onready var dialog_box: Control = get_node("/root/World/DialogBox")

var dialog_registry := {
	"greg": preload("res://Resources/Dialog/npc_greg.tres"),
	"gregsDog": preload("res://Resources/Dialog/npc_gregs_dog.tres"),
	"farmer": preload("res://Resources/Dialog/npc_farmer.tres"),
	"door_guy": preload("res://Resources/Dialog/npc_door_guy.tres")
}

var dialog_resource: DialogResource = null

func _ready():
	if dialog_box != null:
		dialog_box.option_selected.connect(_on_dialog_option_selected)

func show_dialog_by_npc_id(npc_id: String):
	update_dialog(npc_id)
	get_npc_dialog(npc_id)
	if dialog_resource:
		var entry: DialogEntry = null
		for e in dialog_resource.entries:
			if e.state == DialogState.State.ACTIVE:
				entry = e
				break
		show_dialog(npc_id, entry, dialog_resource.npc_name)

func show_dialog_by_entry_id(entry_id: String, npc_id: String):
	if dialog_resource:
		var entry: DialogEntry = dialog_resource.entries.filter(func(e): e.id == entry_id).front()
		show_dialog(npc_id, entry, dialog_resource.npc_name)

func show_dialog(npc_id: String, entry: DialogEntry, npc_name: String):
	if entry:
		dialog_box.show_dialog(npc_id, entry.text, dialog_resource.npc_name, entry.options)
		for flag in entry.flags:
			FlagManager.set_flag(flag)
		QuestManager.validate_active_quest_requirements()
	else:
		push_error("No valid active dialog options for npc_id: " + npc_id)

func update_dialog(npc_id: String):
	var active_dialog_entry: DialogEntry = get_active_dialog_entry(npc_id)
	if active_dialog_entry == null:
		return
	
	var sorted_conditions = dialog_resource.conditions.duplicate()
	sorted_conditions.sort_custom(func(a, b): return a.priority > b.priority)
	
	var should_advance: bool = false
	var next: String = ""
	
	for condition: DialogCondition in sorted_conditions:
		match condition.logic:
			DialogCondition.ConditionLogic.IF_ANY:
				if condition.tasks.any(func(t): return t.validate_task()):
					should_advance = true
					next = condition.next
					break
			DialogCondition.ConditionLogic.IF_ALL:
				if condition.tasks.all(func(t): return t.validate_task()):
					should_advance = true
					next = condition.next
					break
			DialogCondition.ConditionLogic.IF_NONE:
				if !condition.tasks.any(func(t): return t.validate_task()):
					should_advance = true
					next = condition.next
					break

	if should_advance:
		active_dialog_entry.state = DialogState.State.COMPLETED
		if next != "":
			var next_entry := get_entry_by_id(npc_id, next)
			if next_entry:
				next_entry.state = DialogState.State.ACTIVE

func _on_dialog_option_selected(npc_id: String, option: DialogOption):
	# Set flags from this option if it has any
	for flag in option.flags:
		FlagManager.set_flag(flag)
	
	if option.accepted_quest != null:
		QuestManager.accept_quest(option.accepted_quest)

	# Advance to the next dialog entry if it exists
	if option.next != "":
		var next_entry := get_entry_by_id(npc_id, option.next)
		if next_entry:
			set_active_dialog(npc_id, DialogState.State.COMPLETED)
			next_entry.state = DialogState.State.ACTIVE
			show_dialog_by_entry_id(next_entry.id, npc_id)

func is_showing_dialog() -> bool:
	return dialog_box.visible

func get_npc_dialog(npc_id: String) -> DialogResource:
	dialog_resource = dialog_registry.get(npc_id)
	return dialog_resource

func get_active_dialog_entry(npc_id: String) -> DialogEntry:
	var dialog = get_npc_dialog(npc_id)
	# Deliberately skipping catching null for dialog. I want it to blow up when I try and access something
	#  that does not exist
	var matches = dialog.entries.filter(func(entry): return entry.state == DialogState.State.ACTIVE)
	return matches.front()  # Returns the first match or null if empty

func set_active_dialog(npc_id: String, state: int):
	var dialog = get_active_dialog_entry(npc_id)
	dialog.state = state

func get_entry_by_id(npc_id: String, entry_id: String) -> DialogEntry:
	var dialog := get_npc_dialog(npc_id)
	if dialog == null:
		return null

	for entry in dialog.entries:
		if entry.id == entry_id:
			return entry
	return null  # Not found

# Save all dialog entry states across all NPCs
func save_dialogs() -> Dictionary:
	var all_data := {}
	for npc_id in dialog_registry.keys():
		var dialog_data: DialogResource = dialog_registry.get(npc_id)
		if dialog_data == null:
			continue

		var entry_states := {}
		for entry in dialog_data.entries:
			entry_states[entry.id] = entry.state
		
		all_data[npc_id] = entry_states  # Just save { entry_id: state } for each NPC
	return all_data

# Load all dialog entry states from saved data
func load_dialogs(data: Dictionary):
	for npc_id in data.keys():
		var dialog_data: DialogResource = dialog_registry.get(npc_id)
		if dialog_data == null:
			push_warning("Dialog not found for NPC: " + npc_id)
			continue

		var saved_entries: Dictionary = data[npc_id]
		for entry in dialog_data.entries:
			if saved_entries.has(entry.id):
				entry.state = saved_entries[entry.id]
