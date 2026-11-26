extends SceneTree
var game

func _initialize():
	call_deferred("_run")

func _check(ok: bool, message: String) -> bool:
	if not ok:
		push_error(message)
		quit(1)

	return ok

func _run():
	game = load("res://Scenes/Hex/HexBattle.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_battle_active(true)

	if not _check(game.engine.runtime != null, "Engine unavailable"):
		return

	game.paused = false
	game._command({"op": "new", "seed": 42})
	game._command({"op": "coin", "call": "heads"})
	var first: int = 0 if game.engine.state.coin.winner == 0 else 1

	game._command({"op": "first", "side": first})

	if not _check(game.hand.get_child_count() == 5, "Opening hand must show five cards"):
		return

	game._starter()
	await process_frame

	if not _check(game.modal != null, "Starter viewer missing"):
		return

	game._close()
	game._pile(0, "deck")
	await process_frame

	if not _check(game.modal != null, "Deck viewer missing"):
		return

	game._close()
	game._command({"op": "keep"})
	# Complete the opponent's opening turn before setting up the placement check.

	for i in range(50):
		game.ai_timer.stop()

		if game._ai_can_act():
			game._ai_tick()
		elif game.engine.state.response != null and game.engine.state.response.priority == 0:
			game._close()
			game._command({"op": "pass"})
		elif game.engine.state.choice != null and game.engine.state.choice.player == 0:
			game._close()
			game._command({"op": "choice", "index": 0})
		else:
			break

	game.ai_timer.stop()
	game._close()

	if not _check(
		game.engine.state.active == 0 and game.engine.state.phase == "pre",
		"Placement check must reach the player's pre-combat phase"
	):
		return

	# This UI fixture tests placement, not random opening-hand resource availability.

	var setup: String = (
		game
		. engine
		. runtime
		. evaluate(
			"""
		(() => {
		 const g = Hex.dispatch({op:'save'}).game, player = g.players[0];

		 player.planes = Array.from({length:6}, () => hexPlane(HEX_TERRAINS, 0));
		 if (!player.hand.some(c => hexType(c, 'Creature'))) {
		   const index = player.deck.findIndex(c => hexType(c, 'Creature'));
		   if (index < 0) return 'No creature available in fixture deck';
		   player.hand.push(player.deck.splice(index, 1)[0]);
		 }
		 return 'ready';
		})()
		"""
		)
	)

	if not _check(setup == "ready", "Placement fixture failed: " + setup):
		return

	game.engine.request({"op": "view"})
	game._refresh()
	var g: Dictionary = game.engine.state
	var played := false

	for c in g.players[0].hand:
		var options: Array = g.handOptions.get(c.uid, [])

		if game._def(c.id).card_type != "Creature" or options.is_empty():
			continue

		game._clicked(c, {"zone": "hand"})
		await process_frame

		if not _check(
			game.modal == null and not game.targeting.is_empty(),
			"Creature placement must highlight the board without a popup"
		):
			return

		var slot: int = options[0].slot

		if not _check(
			game.stage.target_keys.has(game.stage.key_for(0, slot)),
			"Legal placement hex must be highlighted"
		):
			return

		game._clicked({}, {"zone": "board", "side": 0, "slot": slot})

		if not _check(
			(
				game.engine.state.players[0].board[slot] != null
				and game.engine.state.players[0].board[slot].uid == c.uid
			),
			"Selected creature was not placed on the clicked hex"
		):
			return

		played = true
		break

	if not _check(played, "Placement fixture must provide a playable creature"):
		return

	game._close()
	game._pause()

	if not _check(game.paused, "Save/pause failed"):
		return

	if not _check(game.engine.save_match(), "Save failed"):
		return

	game.paused = false
	game.notice.text = "Click a hand card to play it, or drag it to a slot."
	game._refresh()
	await process_frame
	await process_frame
	await create_timer(1.7).timeout

	if DisplayServer.get_name() != "headless":
		var screenshot := root.get_texture().get_image()

		screenshot.save_png("/tmp/hex-godot-screen.png")

	print("Godot battle scene, hand, starter viewer, deck viewer and save/pause passed")
	game.queue_free()
	await create_timer(0.4).timeout
	quit()
