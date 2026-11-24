extends SceneTree
var game


func _initialize():
	call_deferred("_run")


func _run():
	game = load("res://Scenes/Hex/HexBattle.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_battle_active(true)
	game.paused = false
	game._command({"op": "new", "seed": 42, "enemy": "thornbound"})
	game._command({"op": "coin", "call": "heads"})
	game._command({"op": "first", "side": 0 if game.engine.state.coin.winner == 0 else 1})
	game._command({"op": "keep"})
	var steps := 0
	while game.engine.state.winner == null and steps < 1000:
		game.ai_timer.stop()
		game._close()
		var g: Dictionary = game.engine.state
		var side = (
			g.choice.player
			if g.choice != null
			else g.response.priority if g.response != null else g.active
		)
		if side == 1:
			game._ai_tick()
		else:
			var action = JSON.parse_string(
				game.engine.runtime.evaluate(
					"JSON.stringify(hexAscendedPlan(Hex.dispatch({op:'save'}).game,0))"
				)
			)
			if not action is Dictionary:
				push_error("No legal player action: " + str(action))
				quit(1)
				return
			action.op = action.kind
			action.erase("kind")
			game._command(action)
		game.ai_timer.stop()
		steps += 1
		await process_frame
	if game.engine.state.winner == null:
		push_error("UI match did not finish")
		quit(1)
		return
	print("Complete Godot UI match passed: ", steps, " actions, winner ", game.engine.state.winner)
	game.paused = true
	game.ai_timer.stop()
	await create_timer(0.3).timeout
	if DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png("/tmp/hex-godot-result.png")
	game.queue_free()
	await create_timer(0.4).timeout
	quit()
