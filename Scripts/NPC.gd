class_name NPC
extends Interactable

@export var id: String = ""
@export var display_name: String = ""

var dialog_manager := DialogManager  # Defaults to the singleton


func _ready():
	if CompanionManager.should_hide_npc(id):
		queue_free()
		return
	super._ready()


func _on_interact():
	dialog_manager.show_dialog_by_npc_id(name)
