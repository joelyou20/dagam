extends Node

func save_game_to_file(path: String = "user://savegame.dat"):
	var data := {
		"dialogs": DialogManager.save_all_dialogs(),
		"flags": FlagManager.save_flags()  # Add this function
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var(data)
	file.close()
	
func load_game_from_file(path: String = "user://savegame.dat"):
	if not FileAccess.file_exists(path):
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	var data : Variant = file.get_var()
	file.close()

	DialogManager.load_all_dialogs(data.get("dialogs", {}))
	FlagManager.load_flags(data.get("flags", {}))
