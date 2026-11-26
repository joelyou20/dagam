extends SceneTree
var game
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		quit(1)

		return false

	checks += 1

	return true

func run() -> void:
	game = load("res://Scenes/Hex/HexBattle.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_battle_active(true)
	game.ai_timer.stop()
	game.engine.request({"op": "new", "seed": 42})
	(
		game
		. engine
		. runtime
		. evaluate(
			"""
	(() => {
	 const g=Hex.dispatch({op:'save'}).game;
	 Object.assign(g,{phase:'pre',turn:1,active:0,coin:null,tasks:[],stack:[],choice:null});
	 for(const p of g.players) Object.assign(p,{hand:[],planePlayed:false,board:Array(6).fill(null),planes:Array.from({length:6},()=>hexPlane(['Earth'],0))});
	 function card(id,owner=0){return {id,owner,originalOwner:owner,uid:'hc-'+(++g.serial),spent:{}};}
	 for(const side of [0,1]) {hexExecute(g,{kind:'play',owner:side,card:card('LT-006',side),option:{slot:0}});hexPump(g);}
	 g.players[0].hand=['FD-022','FD-023','FD-024','SA-002'].map(id=>card(id));

	})()
	"""
		)
	)
	game.engine.request({"op": "view"})
	game.paused = false
	game._refresh()
	game.ai_timer.stop()
	await process_frame

	if not check(
		not game.engine.state.players[0].has("power"), "Battle state must have no Power pool"
	):
		return

	if not check(
		game.stage.terrain_tiles.size() == 12, "Every hex must show its terrain and level"
	):
		return

	var fire: Dictionary = game.engine.state.players[0].hand[0]

	game._drop({"kind": "hand", "uid": fire.uid}, {"zone": "board", "side": 0, "slot": 0})

	if not check(
		game.engine.state.players[0].planes[0].get("id") == "FD-022",
		"Plane drag must work on occupied hexes"
	):
		return

	if not check(
		game.engine.state.players[0].board[0] != null, "Changing a Plane must retain its occupant"
	):
		return

	var water: Dictionary = game.engine.state.players[0].hand.filter(func(c): return c.id == "FD-023")[0]

	if not check(
		game.engine.state.handOptions[water.uid].is_empty(), "Second Plane must be unavailable"
	):
		return

	var erupt: Dictionary = game.engine.state.players[0].hand.filter(func(c): return c.id == "FD-024")[0]

	await create_timer(1.5).timeout
	game._inspect(erupt)

	if not check(game.inspection.texture != null, "Card hover must show art"):
		return

	var vanguard := preload("res://Scripts/Hex/HexCardUI.gd").art("SA-024").get_image()

	if not check(
		vanguard.get_pixel(vanguard.get_width() / 2, int(vanguard.get_height() * 0.77)).a == 1.0,
		"Vanguard ability panel must stay opaque without resource overlays"
	):
		return

	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://plane-battle-screen.png")

	game._drop({"kind": "hand", "uid": erupt.uid}, {"zone": "board", "side": 1, "slot": 0})

	if not check(
		game.engine.state.players[1].planes[0].get("id") == "FD-025",
		"Erupt must drag onto an occupied enemy hex"
	):
		return

	if not check(
		game.engine.state.players[1].board[0] != null, "Erupt must not bounce the enemy occupant"
	):
		return

	game.paused = true
	game.ai_timer.stop()
	game.queue_free()
	await create_timer(0.3).timeout
	print("Plane battlefield UI checks passed: ", checks)
	quit()
