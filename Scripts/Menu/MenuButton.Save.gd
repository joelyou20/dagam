extends MenuButtonBase

func _on_pressed():
	GameStateManager.save_game_to_file()
	
