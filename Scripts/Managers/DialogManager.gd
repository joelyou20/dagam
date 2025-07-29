extends Node

@onready var dialog_box: Control = get_node("/root/World/DialogBox")

var dialog_registry := {
	"greg": preload("res://Resources/Dialog/npc_greg.tres"),
	"gregsDog": preload("res://Resources/Dialog/npc_gregs_dog.tres"),
	"farmer": preload("res://Resources/Dialog/npc_farmer.tres")
}

var dialog_resource: DialogResource = null

func _ready():
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
		var entry: DialogEntry = dialog_resource.entries.filter(func(entry): entry.id == entry_id).front()
		show_dialog(npc_id, entry, dialog_resource.npc_name)

func show_dialog(npc_id: String, entry: DialogEntry, npc_name: String):
	if entry:
		dialog_box.show_dialog(npc_id, entry.text, dialog_resource.npc_name, entry.options)
		for flag in entry.flags:
			FlagManager.set_flag(flag)
	else:
		push_error("No valid active dialog options for npc_id: " + npc_id)

func update_dialog(npc_id: String):
	var active_dialog_entry: DialogEntry = get_active_dialog_entry(npc_id)
	if active_dialog_entry == null:
		return
	
	var sorted_conditions = dialog_resource.conditions.duplicate()
	sorted_conditions.sort_custom(func(a, b): return a.priority > b.priority)
	
	for condition: DialogCondition in sorted_conditions:
		var flag_logic := condition.flag_logic
		var flags := condition.flags
		
		var quests := condition.active_quests
		var quest_logic := condition.quest_logic

		var should_advance: bool = false
		
		should_advance = should_advance or flag_logic == DialogCondition.ConditionLogic.IF_ANY and flags.any(func(flag): return FlagManager.is_flag_set(flag))
		should_advance = should_advance or flag_logic == DialogCondition.ConditionLogic.IF_ALL and flags.all(func(flag): return FlagManager.is_flag_set(flag))
		should_advance = should_advance or flag_logic == DialogCondition.ConditionLogic.IF_NONE and not flags.any(func(flag): return FlagManager.is_flag_set(flag))
		
		should_advance = should_advance or quest_logic == DialogCondition.ConditionLogic.IF_ANY and quests.any(func(quest): return QuestManager.is_quest_active(quest))
		should_advance = should_advance or quest_logic == DialogCondition.ConditionLogic.IF_ALL and quests.all(func(quest): return QuestManager.is_quest_active(quest))
		should_advance = should_advance or quest_logic == DialogCondition.ConditionLogic.IF_NONE and not quests.any(func(quest): return QuestManager.is_quest_active(quest))

		if should_advance:
			active_dialog_entry.state = DialogState.State.COMPLETED
			if condition.next != "":
				var next_entry := get_entry_by_id(npc_id, condition.next)
				if next_entry:
					next_entry.state = DialogState.State.ACTIVE
			break  # stop after first matching condition


func _on_dialog_option_selected(npc_id: String, option: DialogOption):
	# Set flags from this option if it has any
	for flag in option.flags:
		FlagManager.toggle_flag(flag)
	
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

func save_dialog(npc_id: String) -> Dictionary:
	var dialog_data : DialogResource = dialog_registry.get(npc_id)
	if dialog_data == null:
		return {}
	
	var entry_states := {}
	for entry in dialog_data.entries:
		entry_states[entry.id] = entry.state
	
	return {
		"npc_id": npc_id,
		"entries": entry_states
	}

func load_dialog(data: Dictionary):
	var npc_id : Variant = data.get("npc_id", "")
	var dialog_data: DialogResource = dialog_registry.get(npc_id)
	if dialog_data == null:
		push_warning("No dialog found for NPC: " + npc_id)
		return
	
	dialog_resource = dialog_data
	var entries : DialogResource = data.get("entries", {})
	
	for entry in dialog_data.entries:
		if entries.has(entry.id):
			entry.state = entries[entry.id]

func save_all_dialogs() -> Dictionary:
	var all_data := {}
	for npc_id in dialog_registry.keys():
		all_data[npc_id] = save_dialog(npc_id)
	return all_data

func load_all_dialogs(data: Dictionary):
	for npc_id in data.keys():
		load_dialog(data[npc_id])
