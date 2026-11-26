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
	for(const p of g.players) Object.assign(p,{hand:[],board:Array(6).fill(null),artifacts:[null,null],discard:[]});
	let n=0;const card=(id)=>({id,uid:'pick-'+(++n),owner:0,originalOwner:0,spent:{}});
	g.players[0].deck=Array.from({length:18},()=>card('LT-001'));
	g.players[0].hand=[card('SA-028')];
	})()
	"""
		)
	)
	game.engine.request({"op": "view"})
	game.paused = false
	game._refresh()
	var spell: Dictionary = game.engine.state.players[0].hand[0]

	game._clicked(spell, {"zone": "hand"})
	await process_frame
	await process_frame
	var picker = game.card_picker

	if not check(
		is_instance_valid(picker) and game.modal == null,
		"Deck search must use the dimmed picker, not a Window"
	):
		return

	if not check(picker.cards.size() == 18, "Search must expose all legal cards"):
		return

	if not check(
		picker.get_child(0) is ColorRect and picker.get_child(0).color.a < 1.0,
		"Picker must have only a translucent background"
	):
		return

	if not check(
		picker.grid.columns > 3 and picker.cards[0].custom_minimum_size.y <= 192,
		"Picker must fit more smaller cards across the screen"
	):
		return

	if not check(
		picker.cards[0].get_theme_stylebox("normal") is StyleBoxEmpty,
		"Card thumbnails must not add opaque panels"
	):
		return

	if not check(
		picker.footer.get_child_count() == 1,
		"Search cards must not have separate named selection buttons"
	):
		return

	var wanted: String = picker.cards[7].card.uid

	for frame in range(4):
		await process_frame

	var point: Vector2 = picker.cards[7].get_global_rect().get_center()

	for pressed in [true, false]:
		var click := InputEventMouseButton.new()

		click.position = point
		click.global_position = point
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		root.push_input(click, true)
		await process_frame

	if not check(
		game.engine.state.players[0].hand.any(func(c): return c.uid == wanted),
		"Clicking the card must execute its exact search option"
	):
		return

	if not check(game.card_picker == null, "Selection must dismiss the picker"):
		return

	(
		game
		. engine
		. runtime
		. evaluate(
			"""
	(() => {
	const g=Hex.dispatch({op:'save'}).game;
	const c={id:'LT-006',uid:'revive-picker',owner:0,originalOwner:0,spent:{}};
	g.players[0].discard=[c];hexElderReanimate(g,0,[c],'raise');
	})()
	"""
		)
	)
	game.engine.request({"op": "view"})
	game._refresh()

	if not check(
		game.card_picker.cards.size() == 1, "Reanimation must show each discarded creature once"
	):
		return

	game.card_picker.cards[0].pressed.emit()

	if not check(
		game.card_picker == null and game.targeting.destinations.size() == 6,
		"Clicking the creature must proceed to board placement"
	):
		return

	game._clicked({}, {"zone": "board", "side": 0, "slot": 3})

	if not check(
		game.engine.state.players[0].board[3].uid == "revive-picker",
		"Board placement must resolve the selected discarded creature"
	):
		return

	game.set_battle_active(false)
	game.queue_free()
	await create_timer(0.5).timeout
	print("Compact card picker checks passed: ", checks)
	quit()
