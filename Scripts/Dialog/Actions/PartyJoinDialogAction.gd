extends DialogAction
class_name PartyJoinDialogAction

@export var ally_id: String
@export var remove_npc: bool = true

func execute():
	var ally_data = load("res://Resources/Allies/%s.tres" % ally_id)
	if ally_data:
		PartyManager.add_member(ally_data)

	if remove_npc:
		DialogManager.dialog_ui.ui_closed.connect(func(): _on_ui_closed())
				
func _on_ui_closed():
	var npc_nodes = SceneManager.get_tree().get_nodes_in_group("NPC") as Array[NPC]
	for npc in npc_nodes:
		if npc.id == ally_id:
			npc.queue_free()
