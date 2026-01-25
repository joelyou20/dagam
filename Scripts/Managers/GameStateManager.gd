extends Node

func save_game_to_file(path: String = "user://savegame.dat"):
	var player_node = PlayerManager.get_player_node()
	var data := {
		"dialogs": DialogManager.save_dialogs(),
		"flags": FlagManager.save_flags(),
		"quests": QuestManager.save_quests(),
		"inventory": InventoryManager.save_inventory(),
		"player": PlayerManager.save_player(),
		"party": PartyManager.save_party(),
		"deck_manager": DeckManager.save_deck_manager(),
		"player_scene": get_tree().current_scene.scene_file_path,
		"player_position": player_node.global_transform.origin  # Use .global_position for 2D
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var(data)
	print("Game saved to " + path)
	file.close()

func load_game_from_file(path: String = "user://savegame.dat"):
	MenuManager.hide_menu()
	
	if not FileAccess.file_exists(path):
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	var data : Variant = file.get_var()
	file.close()

	# Scene and position come first
	var scene_path = data.get("player_scene", "")
	var player_position = data.get("player_position", Vector3.ZERO)

	if scene_path != "":
		await SceneManager.load_scene(scene_path, true, false)
		
		# Defer position assignment until scene loads
		await get_tree().create_timer(0.1).timeout
		
		var player_node = PlayerManager.get_player_node()
		if player_node:
			player_node.global_transform.origin = player_position  # Use .global_position for 2D
			
		SceneManager.fade_layer.fade_in()

	# Load systems
	DialogManager.load_dialogs(data.get("dialogs", {}))
	FlagManager.load_flags(data.get("flags", {}))
	QuestManager.load_quests(data.get("quests", {}))
	InventoryManager.load_inventory(data.get("inventory", {}))
	PlayerManager.load_player(data.get("player", {}))
	PartyManager.load_party(data.get("party", {}))
	DeckManager.load_deck_manager(data.get("deck_manager", {}))

	print("Game loaded from " + path)
