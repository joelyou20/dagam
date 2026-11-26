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
	for(const p of g.players) Object.assign(p,{hand:[],planePlayed:false,board:Array(6).fill(null),planes:Array.from({length:6},()=>hexPlane(HEX_TERRAINS,0))});
	function card(id,owner=0){return {id,owner,originalOwner:owner,uid:'ui-'+(++g.serial),spent:{}};}
	for(const side of [0,1]) {hexExecute(g,{kind:'play',owner:side,card:card('LT-006',side),option:{slot:0}});hexPump(g);}
	g.players[0].hand=[card('FD-022')];
	g.players[0].board[0].hp-=1;
	g.effectSource=g.players[1].board[0];
	hexAsk(g,0,'Choose a creature to heal',[{label:'Heal creature',task:{kind:'planeHeal',owner:0,target:g.players[0].board[0].uid}}],true);
	delete g.effectSource;
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
		game.modal == null and not game.targeting.is_empty(), "Board choice must not open a modal"
	):
		return

	if not check(
		game.target_overlay.active and game.target_overlay.points.size() == 1,
		"Choice must show its aiming arrow and target"
	):
		return

	if not check(game.stage.target_keys == ["board-0-0"], "Only legal target slots should pulse"):
		return

	var source: Dictionary = game.engine.state.players[1].board[0]

	if not check(
		game.stage.resolving_uid == source.uid, "Trigger source must animate separately from target"
	):
		return

	game._inspect(source)

	if not check(
		game.status_display.tooltip.visible, "Source inspection must show its resolving ability"
	):
		return

	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://direct-targeting.png")

	var before: float = game.engine.state.players[0].board[0].hp

	game._clicked({}, {"zone": "board", "side": 1, "slot": 2})

	if not check(not game.targeting.is_empty(), "Invalid target must not resolve a choice"):
		return

	game._clicked(game.engine.state.players[0].board[0], {"zone": "board", "side": 0, "slot": 0})

	if not check(
		game.engine.state.choice == null and game.engine.state.players[0].board[0].hp == before + 1,
		"Board click must execute the selected engine choice"
	):
		return

	if not check(
		game.targeting.is_empty() and not game.target_overlay.active,
		"Resolved choices must clear targeting cues"
	):
		return

	var plane: Dictionary = game.engine.state.players[0].hand[0]

	game._clicked(plane, {"zone": "hand"})

	if not check(
		game.modal == null and game.targeting.destinations.size() == 6,
		"Plane placement must select directly from all six friendly hexes"
	):
		return

	game._clicked({}, {"zone": "board", "side": 0, "slot": 4})

	if not check(
		game.engine.state.players[0].planes[4].types == [],
		"Clicking an empty hex must play the Plane there"
	):
		return

	(
		game
		. engine
		. runtime
		. evaluate(
			"""
	(() => {
	const g=Hex.dispatch({op:'save'}).game;
	g.players[0].planes=Array.from({length:6},()=>hexPlane(HEX_TERRAINS,0));

	g.players[0].hand=[{id:'SA-008',owner:0,originalOwner:0,uid:'mind-control',spent:{}}];
	})()
	"""
		)
	)
	game.engine.request({"op": "view"})
	game._refresh()
	var control: Dictionary = game.engine.state.players[0].hand[0]

	game._clicked(control, {"zone": "hand"})

	if not check(
		game.modal == null and game.stage.target_keys.has("board-1-0"),
		"Mind Control must begin by selecting its enemy creature"
	):
		return

	game._clicked(game.engine.state.players[1].board[0], {"zone": "board", "side": 1, "slot": 0})

	if not check(
		game.modal == null and game.stage.target_keys.has("board-0-4"),
		"Mind Control must then select a friendly destination without a list"
	):
		return

	game._clicked({}, {"zone": "board", "side": 0, "slot": 4})

	if not check(
		(
			game.engine.state.players[0].board[4] != null
			and game.engine.state.players[1].board[0] == null
		),
		"The two-step selection must apply its original engine option"
	):
		return

	game.set_battle_active(false)
	game.queue_free()
	await create_timer(0.5).timeout
	print("Direct battlefield targeting checks passed: ", checks)
	quit()
