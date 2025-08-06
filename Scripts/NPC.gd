extends Interactable
class_name NPC

@export var id: String = ""
@export var display_name: String = ""

var dialog_manager := DialogManager  # Defaults to the singleton

func _on_interact():
	dialog_manager.show_dialog_by_npc_id(name)
