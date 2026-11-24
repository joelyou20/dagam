extends SceneTree
var checks := 0
var game

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		quit(1)

		return

	checks += 1

func run() -> void:
	game = load("res://Scenes/Hex/HexBattle.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.music.stop()
	game.music.stream = null
	game.set_battle_active(true)
	game.paused = true
	game.engine.request({"op": "new", "seed": 42})
	game.engine.request({"op": "coin", "call": "heads"})
	game.engine.request({"op": "first", "side": 0})
	var saved = game.engine.request({"op": "save"}).game
	var card: Dictionary = {"id": "LT-001", "uid": "status-fixture", "owner": 0, "originalOwner": 0}

	card.merge(
		{
			"slot": 0,
			"hp": 3,
			"maxHp": 3,
			"mods": [],
			"spent": {},
			"shield": 4,
			"wardRemaining": 2,
			"stunUntil": 4,
			"burn": {"due": 2},
			"invisibleUntil": 3,
			"zeroAttackUntil": -1
		},
		true
	)
	saved.players[0].board[0] = card
	saved.turn = 2
	saved.phase = "pre"
	saved.active = 0
	var loaded = game.engine.request({"op": "load", "game": saved})

	check(loaded.get("ok", false), "Status fixture must load through native bridge")
	var live: Dictionary = game.engine.state.players[0].board[0]
	var effects: Array = live.statuses
	var ids = effects.map(func(effect): return effect.id)

	for id in ["shield", "ward", "stun", "burn", "invisible"]:
		check(id in ids, "Missing live status: " + id)

	check(not "zero-attack" in ids, "Expired effects must not be displayed")
	check(
		effects.filter(func(effect): return effect.id == "ward")[0].amount == 2,
		"Ward must display remaining charges"
	)
	game._refresh()
	await process_frame
	game._inspect(live)
	await process_frame
	await process_frame
	var tooltip = game.status_display.tooltip
	var background = tooltip.get_theme_stylebox("panel") as StyleBoxFlat

	check(tooltip.visible, "Hover must reveal live statuses")
	check(
		background.bg_color.a > 0 and background.bg_color.a < 1,
		"Hover background must be translucent"
	)
	check(
		background.border_width_left == 0 and background.border_width_top == 0,
		"Hover background must have no border"
	)
	check(
		tooltip.position.x >= game.inspection.get_rect().end.x,
		"Status list must sit beside the card"
	)
	check(tooltip.get_rect().end.x <= game.size.x, "Status list must stay on screen")
	var symbols = game.stat_badges[live.uid].get_children().filter(
		func(child): return child.get_script() == load("res://Scripts/Hex/HexStatusIcon.gd")
	)

	check(symbols.size() == effects.size(), "Every active status needs a board symbol")
	game.inspection.hide()
	check(not tooltip.visible, "Status list must hide with card preview")
	game._inspect(live)

	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		root.get_texture().get_image().save_png("user://hex-statuses.png")

	# Charges and timers are re-evaluated on every engine view.

	saved.players[0].board[0].wardRemaining = 0
	saved.players[0].board[0].stunUntil = 1
	game.engine.request({"op": "load", "game": saved})
	ids = game.engine.state.players[0].board[0].statuses.map(func(effect): return effect.id)
	check(not "ward" in ids and not "stun" in ids, "Consumed Ward and expired stun must disappear")
	game._refresh()
	check(not tooltip.visible, "Refreshing the battle must clear stale hover effects")
	var fixture: Dictionary = saved.players[0].board[0]

	fixture.merge(
		{
			"mods": [{"attack": 2, "until": 2}, {"attack": 9, "until": 1}],
			"grants": [{"id": "sprint", "until": 2}, {"id": "ranged", "until": 1}],
			"tauntUntil": 2,
			"reflectUntil": 2,
			"noShieldUntil": 2,
			"zeroAttackUntil": 2,
			"fuses": 1,
			"charge": 2,
			"pebbles": 3,
			"gold": 1,
			"channel": 2,
			"scars": 1,
			"sacrificeAtEnd": 2,
			"enraptureDue": 3,
			"control": {"owner": 1, "slot": 0, "until": 2}
		},
		true
	)
	game.engine.request({"op": "load", "game": saved})
	effects = game.engine.state.players[0].board[0].statuses
	ids = effects.map(func(effect): return effect.id)

	for id in [
		"taunt",
		"reflect",
		"no-shield",
		"zero-attack",
		"fuses",
		"charge",
		"pebbles",
		"gold",
		"channel",
		"scars",
		"sacrifice",
		"delayed-stun",
		"control",
		"attack",
		"grant-sprint"
	]:
		check(id in ids, "Missing applied effect or counter: " + id)

	check(not "grant-ranged" in ids, "Expired granted ability must disappear")
	check(
		effects.filter(func(effect): return effect.id == "attack")[0].amount == 2,
		"Expired modifiers must not be counted"
	)
	game._refresh()
	game._inspect(game.engine.state.players[0].board[0])
	await process_frame
	await process_frame
	check(tooltip.get_rect().end.y <= game.size.y, "Long status lists must stay within the screen")

	game.music.stop()
	await process_frame
	game.queue_free()
	await process_frame
	print("Creature status presentation checks passed: ", checks)
	quit(0)
