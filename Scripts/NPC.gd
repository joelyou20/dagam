extends Interactable
class_name NPC

@export var display_name: String = ""

func _on_interact():
	DialogManager.show_dialog_by_npc_id(name)
