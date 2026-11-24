extends SceneTree
var game
var checks:=0
func _initialize(): call_deferred("run")
func check(ok: bool,message: String) -> bool:
	if not ok: push_error(message);quit(1);return false
	checks+=1
	return true
func frames():
	await process_frame
	await process_frame
func run():
	game=load("res://Scenes/Hex/HexBattle.tscn").instantiate();root.add_child(game)
	await frames()
	game.set_battle_active(true);game.paused=false
	game._command({"op":"new","seed":42})
	game._command({"op":"coin","call":"heads"})
	game._command({"op":"first","side":0 if game.engine.state.coin.winner==0 else 1})
	await frames()
	if not check(game.stage.viewport.size.x>=game.stage.size.x*1.49 and game.stage.viewport.size.y>=game.stage.size.y*1.49,"3D viewport must supersample the displayed resolution"): return
	if not check(game.stage.position==Vector2.ZERO and game.stage.size==game.size,"Battlefield must fill the window behind the hand"): return
	if not check(game.stage.camera.position.y>0 and game.stage.camera.position.z>0,"Camera must be angled above the board"): return
	for pile in game.board.get_children():
		if pile is Button and "Discard" in pile.text:
			if not check(not pile.get_global_rect().intersects(game.controls.get_parent().get_global_rect()),"Turn panel covers a discard control: "+str(pile.get_global_rect())+" vs "+str(game.controls.get_parent().get_global_rect())): return
	var draws=game.overlay.get_children().filter(func(n):return n is TextureRect and n!=game.inspection)
	if not check(draws.size()==5,"Opening hand must animate five cards from deck"): return
	await create_timer(0.7).timeout
	if not check(draws.all(func(n):return not is_instance_valid(n)),"Draw ghosts were not cleaned up"): return
	for side in [0,1]:
		for slot in range(6):
			var rect=game.stage.slot_rect(side,slot)
			if not check(Rect2(Vector2.ZERO,game.stage.size).encloses(rect),"A creature slot lies outside the camera frame"): return
	game._command({"op":"keep"})
	for i in range(50):
		if not game._ai_can_act(): break
		game.ai_timer.stop();game._ai_tick()
	var played={}
	for card in game.engine.state.players[0].hand:
		var options: Array=game.engine.state.handOptions.get(card.uid,[])
		if game._def(card.id).card_type=="Creature" and not options.is_empty():
			played=card
			game._drop({"kind":"hand","uid":card.uid},{"zone":"board","side":0,"slot":options[0].slot})
			break
	if not check(not played.is_empty(),"No creature could be placed by drag destination"): return
	var node=game.stage.find_piece(played.uid)
	if not check(node!=null and node.get_node("Art").mesh is PlaneMesh,"Played creature must become a textured 3D card"): return
	await create_timer(0.6).timeout
	if not check(node.position.is_equal_approx(node.get_meta("home")),"Card placement did not settle on its slot"): return
	if not check(node.get_children().all(func(n):return not n is Label3D),"Card names/stats must not be rasterized as world-space labels"): return
	if not check(game.stat_badges.has(played.uid),"Crisp combat stats missing"): return
	game._inspect(played)
	if not check(game.inspection is TextureRect and game.inspection.get_child_count()==0,"Hover must show only the card"): return
	if not check(game.inspection.texture.get_width()==1024 and game.inspection.size.y>=game.size.y*0.7,"Hover card must be large and use HD artwork"): return
	game.inspection.visible=false
	if DisplayServer.get_name()!="headless":
		await create_timer(1.2).timeout
		root.get_texture().get_image().save_png("user://hex-3d-board.png")
	var serial=game.engine.state.players[0].board.filter(func(c):return c!=null).size()
	game.stage.effects([{"kind":"damage","uid":played.uid,"amount":2},{"kind":"heal","uid":played.uid,"amount":1}])
	if not check(game.overlay.get_children().filter(func(n):return n.has_meta("damage_number")).size()==2,"Damage and healing should display together"): return
	await create_timer(0.9).timeout
	if not check(game.overlay.get_children().filter(func(n):return n.has_meta("damage_number")).is_empty(),"Floating damage labels leaked"): return
	if not check(game.engine.state.players[0].board.filter(func(c):return c!=null).size()==serial,"Presentation changed authoritative game state"): return
	game.set_battle_active(false)
	if not check(game.stage.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Hidden arena must stop rendering"): return
	print("3D board, draw, placement, targeting and effect checks passed: ",checks)
	game.queue_free();await create_timer(0.5).timeout;quit()
