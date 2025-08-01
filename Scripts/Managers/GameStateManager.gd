extends Node

func save_game_to_file(path: String = "user://savegame.dat"):
	var data := {
		"dialogs": DialogManager.save_dialogs(),
		"flags": FlagManager.save_flags(),
		"quests": QuestManager.save_quests(),
		"inventory": InventoryManager.save_inventory()
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var(data)
	print("Game saved to " + path)
	file.close()
	
func load_game_from_file(path: String = "user://savegame.dat"):
	if not FileAccess.file_exists(path):
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	var data : Variant = file.get_var()
	file.close()

	DialogManager.load_dialogs(data.get("dialogs", {}))
	FlagManager.load_flags(data.get("flags", {}))
	QuestManager.load_quests(data.get("quests", {}))
	InventoryManager.load_inventory(data.get("inventory", {}))
	
	print("Game loaded from " + path)
