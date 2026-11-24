class_name PartyJoinDialogAction
extends DialogAction

@export var ally_id: String
@export var remove_npc: bool = true


func execute():
	# Add ally
	var ally_data = load("res://Resources/Allies/%s.tres" % ally_id)
	if ally_data:
		CompanionManager.recruit(ally_data, remove_npc)

	# Remove NPC if flagged
	if remove_npc:
		var npc_nodes = SceneManager.get_tree().get_nodes_in_group("NPC") as Array[NPC]
		for npc in npc_nodes:
			if npc.id == ally_id:
				npc.queue_free()
