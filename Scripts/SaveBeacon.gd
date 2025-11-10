extends Interactable

func _on_interact():
	MenuManager.set_menu(true, MenuTabs.Tab.OPTIONS)
