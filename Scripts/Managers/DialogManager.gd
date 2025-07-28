extends Node

@onready var dialog_box: Control = get_node("/root/World/DialogBox")

var dialog_registry := {
	"greg": preload("res://Resources/Dialog/npc_greg.tres"),
	"farmer": preload("res://Resources/Dialog/npc_farmer.tres")
}

var current_dialog: DialogResource = null

func _ready():
	dialog_box.option_selected.connect(_on_dialog_option_selected)

func show_dialog_by_npc_id(npc_id: String):
	update_dialog(npc_id)
	get_npc_dialog(npc_id)
	if current_dialog:
		var entry: DialogEntry = null
		for e in current_dialog.entries:
			if e.state == DialogState.State.ACTIVE:
				entry = e
				break
		if entry:
			dialog_box.show_dialog(npc_id, entry.text, current_dialog.npc_name, entry.options)
		else:
			push_error("No valid active dialog options for npc_id: " + npc_id)

func show_dialog_by_entry_id(entry_id: String, npc_id: String):
	if current_dialog:
		var entry: DialogEntry = current_dialog.entries.filter(func(entry): entry.id == entry_id).front()
		if entry:
			dialog_box.show_dialog(npc_id, entry.text, current_dialog.npc_name, entry.options)
		else:
			push_error("No valid active dialog options for npc_id: " + npc_id)

func update_dialog(npc_id: String):
	var active_dialog: DialogEntry = get_active_dialog(npc_id)
	if active_dialog == null:
		return

	for condition in current_dialog.conditions:
		var logic := condition.logic
		var flags := condition.flags

		var should_advance := (
			(logic == DialogCondition.ConditionLogic.IF_ANY and flags.any(func(flag): return FlagManager.is_flag_set(flag))) or
			(logic == DialogCondition.ConditionLogic.IF_ALL and flags.all(func(flag): return FlagManager.is_flag_set(flag))) or
			(logic == DialogCondition.ConditionLogic.IF_NONE and not flags.any(func(flag): return FlagManager.is_flag_set(flag)))
		)

		if should_advance:
			active_dialog.state = DialogState.State.COMPLETED
			if condition.next != "":
				var next_entry := get_entry_by_id(npc_id, condition.next)
				if next_entry:
					next_entry.state = DialogState.State.ACTIVE
			break  # stop after first matching condition


func _on_dialog_option_selected(option: DialogOption):
	for flag in option.flags:
		FlagManager.toggle_flag(flag)
	
	# Optionally do something like:
	# - Advance a dialog state
	# - Modify world/NPC state
	# - Trigger cutscenes/quests/etc.

func is_showing_dialog() -> bool:
	return dialog_box.visible

func get_npc_dialog(npc_id: String) -> DialogResource:
	current_dialog = dialog_registry.get(npc_id)
	return current_dialog

func get_active_dialog(npc_id: String) -> DialogEntry:
	var dialog = get_npc_dialog(npc_id)
	var matches = dialog.entries.filter(func(entry): return entry.state == DialogState.State.ACTIVE)
	return matches.front()  # Returns the first match or null if empty

func set_active_dialog(npc_id: String, state: int):
	var dialog = get_active_dialog(npc_id)
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
	
	current_dialog = dialog_data
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
