extends Node
var world: Node
var checks := 0
func _ready(): call_deferred("_run")
func check(value: bool,message: String) -> bool:
	if not value:
		push_error(message)
		get_tree().quit(1)
		return false
	checks += 1
	return true
func frames():
	await get_tree().process_frame
	await get_tree().process_frame
func _run():
	world = load("res://Scenes/Root.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	for i in range(12): await get_tree().process_frame
	if not check(not HexManager.initialized,"Hex must stay lazy until opened"): return
	HexManager.open_battle()
	await frames()
	var hex: HexBattleUI = HexManager.battle_ui
	if not check(hex.visible and UIManager.top()==hex and hex.get_parent()==get_tree().root,"Battle must be a dedicated root UI"): return
	if not check(InteractionHandler.is_blocked(),"Hex must block world interaction"): return
	if not check(HexManager.initialized and hex.battle.engine==HexManager.session,"Manager does not own match"): return
	if not check(HexManager.session.catalog.starter.size()==20,"Starter must contain 20 cards"): return
	hex.battle._command({"op":"new", "seed":42})
	var original: Dictionary = HexManager.save_hex()
	if not check(MenuManager.menu_ui==null,"Opening battle instantiated the RPG menu"): return
	if not check(hex.battle.size==get_viewport().get_visible_rect().size,"Battle does not fill the window"): return
	if not check(get_window().disable_3d and not hex.battle.stage.viewport.disable_3d,"Battle must render only its own 3D world"): return
	HexManager.close_battle(true)
	if not check(not get_window().disable_3d,"Closing battle must restore world rendering"): return
	MenuManager.set_menu(true, MenuTabs.Tab.OPTIONS)
	await frames()
	if not check(hex.battle.paused and hex.battle.ai_timer.is_stopped(),"Hidden Hex kept AI running"): return
	HexManager.open_battle()
	await frames()
	if not check(HexManager.save_hex().game.serial==original.game.serial,"Reopening replaced the game"): return
	GameStateManager.save_game_to_file("user://hex-integration-game.dat")
	var file := FileAccess.open("user://hex-integration-game.dat",FileAccess.READ)
	var saved: Dictionary = file.get_var()
	file.close()
	if not check(saved.has("hex") and saved.has("inventory") and saved.has("party"),"Shared save is incomplete"): return
	HexManager.request({"op":"coin","call":"heads"})
	await GameStateManager.load_game_from_file("user://hex-integration-game.dat")
	if not check(HexManager.session.state.phase==original.game.phase,"Shared load did not restore Hex"): return
	if not check(SceneManager.current_scene.scene_file_path==saved.player_scene,"World scene was not restored"): return
	if not check(InventoryManager.save_inventory()==saved.inventory,"RPG inventory changed during load"): return
	if not check(HexManager.load_hex({}),"Legacy RPG save without Hex rejected"): return
	HexManager.open_battle()
	await frames()
	hex.battle._starter()
	if not check(UIManager.handle_cancel() and hex.battle.modal==null and hex.visible,"Escape must dismiss the dialog first"): return
	if not check(UIManager.handle_cancel(),"Escape did not close Hex"): return
	if not check(not hex.visible and hex.battle.paused,"Hex did not pause on Escape"): return
	if not check(not InteractionHandler.is_blocked(),"World input stayed blocked"): return
	if not check(ProjectSettings.get_setting("application/run/main_scene")=="res://Scenes/Root.tscn","Original entry scene changed"): return
	var hotkey := InputEventAction.new()
	hotkey.action="toggle_hex_menu"
	hotkey.pressed=true
	world._unhandled_input(hotkey)
	await frames()
	if not check(not hex.visible and MenuManager.menu_ui.content_uis.Hex.visible,"H must open the deck builder, not battle"): return
	world._unhandled_input(hotkey)
	if not check(not MenuManager.menu_ui.visible and not InteractionHandler.is_blocked(),"H did not close deck builder and restore world control"): return
	print("Root-project Hex integration checks passed: ",checks)
	if DisplayServer.get_name()!="headless":
		HexManager.open_battle()
		await frames()
		var controller=hex.battle
		controller._command({"op":"coin","call":"heads"})
		controller._command({"op":"first","side":0 if controller.engine.state.coin.winner==0 else 1})
		controller._command({"op":"keep"})
		for i in range(40):
			if not controller._ai_can_act(): break
			controller.ai_timer.stop()
			controller._ai_tick()
			await get_tree().process_frame
		for c in controller.engine.state.players[0].hand:
			var options: Array=controller.engine.state.handOptions.get(c.uid,[])
			if controller._def(c.id).card_type=="Creature" and not options.is_empty():
				controller._inspect(c)
				controller._command({"op":"play","uid":c.uid,"index":options[0].index})
				break
		controller.paused=true
		controller.ai_timer.stop()
		await get_tree().create_timer(1.8).timeout
		controller.inspection.visible=false
		await frames()
		get_tree().root.get_texture().get_image().save_png("user://hex-integrated-screen.png")
		var card=controller.engine.state.players[0].hand.front()
		controller._inspect(card)
		await frames()
		get_tree().root.get_texture().get_image().save_png("user://hex-hover-screen.png")
	HexManager.save_match()
	if is_instance_valid(MenuManager.menu_ui): MenuManager.menu_ui.queue_free()
	HexManager.battle_ui.queue_free()
	world.queue_free()
	await get_tree().create_timer(0.4).timeout
	get_tree().quit()
