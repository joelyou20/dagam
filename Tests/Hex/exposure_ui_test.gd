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
	 Object.assign(g,{active:0,turn:5,phase:'post',coin:null,stack:[],tasks:[],choice:null});
	 for(const p of g.players)Object.assign(p,{hand:[],board:Array(6).fill(null),artifacts:[null,null],planes:Array.from({length:6},()=>hexPlane(['Earth'],0)),power:[],exposure:0,losses:0});
	 hexExecute(g,{kind:'play',owner:1,card:{id:'LT-006',uid:'enemy',owner:1,originalOwner:1,spent:{}},option:{slot:0}});hexPump(g);
	 g.players[0].exposure=2;g.players[0].losses=1;g.players[1].exposure=1;
	})()
	"""
		)
	)
	game.engine.request({"op": "view"})
	game.paused = false
	game._refresh()
	game.ai_timer.stop()
	await process_frame
	var ui = game.exposure_ui

	if not check(
		ui.markers[0].count == 2 and ui.markers[1].count == 1,
		"Both sides need separate Exposure markers"
	):
		return

	if not check(
		ui.warning.visible and "avoid defeat" in ui.warning.text,
		"Two Exposure must show a clear warning"
	):
		return

	if not check(
		"1 / 6" in game.player_summary.text,
		"Exposure must not replace or increment the death counter"
	):
		return

	if not check(
		ui.markers[0].tooltip_text.contains("Both fields empty"),
		"Tooltip must explain empty-field pause"
	):
		return

	await create_timer(2.2).timeout

	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://exposure-warning.png")

	game._command({"op": "next"})
	game.ai_timer.stop()

	if not check(
		game.engine.state.winner == 1 and game.engine.state.reason == "exposure",
		"Third Exposure must finish the actual UI match"
	):
		return

	if not check(
		ui.markers[0].count == 3 and not ui.warning.visible,
		"Defeat must fill all markers and dismiss the warning"
	):
		return

	if not check(
		game.engine.state.players[0].losses == 1,
		"Exposure loss must preserve actual creature death count"
	):
		return

	(
		game
		. engine
		. runtime
		. evaluate(
			"""
	(() => {
	 const g=Hex.dispatch({op:'save'}).game;Object.assign(g,{winner:null,lossReason:null,phase:'post',active:0,stack:[],tasks:[],choice:null});
	 g.players[0].exposure=2;
	 hexExecute(g,{kind:'play',owner:0,card:{id:'LT-006',uid:'rescued',owner:0,originalOwner:0,spent:{}},option:{slot:0}});hexPump(g);
	})()
	"""
		)
	)
	game.engine.request({"op": "view"})
	game._command({"op": "next"})
	game.ai_timer.stop()

	if not check(
		ui.markers[0].count == 0 and game.engine.state.winner == null,
		"Ending with a creature must clear markers and survive"
	):
		return

	game.paused = true
	game.queue_free()
	await create_timer(0.3).timeout
	print("Exposure UI marker, warning, defeat and recovery checks passed: ", checks)
	quit()
