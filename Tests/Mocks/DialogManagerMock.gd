extends DialogManager
class_name DialogManagerMock

var called_with_npc_ids = []

func show_dialog_by_npc_id(npc_id: String):
	called_with_npc_ids.append(npc_id)
