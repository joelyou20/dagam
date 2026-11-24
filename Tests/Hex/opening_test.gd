extends Node
var game
var checks:=0
func _ready():call_deferred("run")
func check(ok: bool,message: String) -> bool:
	if not ok:push_error(message);get_tree().quit(1);return false
	checks+=1;return true
func frames():
	await get_tree().process_frame
	await get_tree().process_frame
func start(seed: int):
	game.paused=false;game._command({"op":"new","seed":seed});await frames()
func run():
	game=load("res://Scenes/Hex/HexBattle.tscn").instantiate();add_child(game);await frames();game.set_battle_active(true)
	await start(42)
	var ui=game.opening
	if not check(ui.visible and ui.buttons.get_child_count()==2,"Opening must show centered heads/tails choices"):return
	if not check(ui.panel.get_global_rect().get_center().distance_to(game.get_global_rect().get_center())<2,"Coin prompt is not centered"):return
	if not check(game.controls.get_child_count()==0,"Coin choices still appear in side controls"):return
	# Use the actual call button, not an out-of-band state mutation.
	var predicted=game.engine.runtime.evaluate("hexRand(JSON.parse(JSON.stringify(Hex.dispatch({op:'save'}).game)))<.5?'heads':'tails'")
	ui.buttons.get_child(0 if predicted=="heads" else 1).pressed.emit();await frames()
	if not check(game.engine.state.phase=="coinResult" and ui.coin.flipping,"Coin animation did not start from a real call"):return
	var angle=ui.coin.angle
	if not check(ui.buttons.get_child_count()==0,"Turn-order buttons appeared before coin landed"):return
	await get_tree().create_timer(0.3).timeout
	if not check(ui.coin.angle!=angle,"Coin does not rotate"):return
	var rolled=game.engine.state.coin.duplicate()
	game._refresh()
	if not check(game.engine.state.coin==rolled,"Refreshing animation rerolled coin"):return
	await get_tree().create_timer(1.5).timeout
	if not check(not ui.coin.flipping,"Coin did not settle"):return
	if not check(is_equal_approx(absf(cos(ui.coin.angle)),1.0),"Coin did not land face-on"):return
	if not check((cos(ui.coin.angle)<0)==(rolled.face=="tails"),"Animated face disagrees with seeded result"):return
	if rolled.winner==0:
		if not check(ui.buttons.get_child_count()==2,"Winner cannot choose first or second"):return
		ui.buttons.get_child(0).pressed.emit()
	else:
		await get_tree().create_timer(1.1).timeout
	game.ai_timer.stop();await frames()
	if not check(game.engine.state.phase=="opening" and game.engine.state.players[0].hand.size()==5,"Coin result did not lead to the opening hand"):return
	if not check(not ui.visible,"Coin overlay remained over opening hand"):return
	game._command({"op":"mulligan"});game.ai_timer.stop()
	if not check(game.engine.state.phase=="pre" and game.engine.state.turn==1,"Mulligan did not immediately start turn one"):return
	if not check(game.engine.state.players[0].mulligan and game.engine.state.players[0].hand.size()==5,"Redraw did not produce exactly five cards"):return
	var saved=HexManager.save_hex()
	if not check(not HexManager.request({"op":"keep"}).ok and game.engine.state.turn==1,"Keep advanced an already started turn"):return
	# Legacy opening saves after a redraw should resume directly into turn one.
	await start(52);game._command({"op":"coin","call":"heads"});game._command({"op":"first","side":0 if game.engine.state.coin.winner==0 else 1})
	var legacy=HexManager.save_hex();legacy.game.players[0].mulligan=true
	game.engine.request({"op":"load","game":legacy.game})
	if not check(game.engine.state.phase=="pre" and game.engine.state.turn==1,"Legacy redraw save still requires Keep"):return
	var resumed=game.engine.request({"op":"save"});game.engine.request({"op":"load","game":resumed.game})
	if not check(game.engine.state.turn==1,"Reloading auto-kept save advanced another turn"):return
	# Reopening an already resolved toss reveals its existing result, not a new flip.
	await start(62);game._command({"op":"coin","call":"tails"})
	var outcome=game.engine.state.coin.duplicate();game.set_battle_active(false);game.set_battle_active(true);await frames()
	if not check(not ui.coin.flipping and game.engine.state.coin==outcome,"Resume restarted or rerolled a resolved toss"):return
	# Both turn-order choices remain available to the winning player.
	await start(72)
	predicted=game.engine.runtime.evaluate("hexRand(JSON.parse(JSON.stringify(Hex.dispatch({op:'save'}).game)))<.5?'heads':'tails'")
	game._command({"op":"coin","call":predicted});game.set_battle_active(false);game.set_battle_active(true);await frames()
	ui.buttons.get_child(1).pressed.emit();await frames()
	if not check(game.engine.state.phase=="opening" and game.engine.state.first==1,"Go second choice was lost"):return
	game._command({"op":"keep"});game.ai_timer.stop()
	if not check(game.engine.state.phase=="pre" and game.engine.state.turn==1 and game.engine.state.active==1,"Keeping the original hand no longer starts the chosen first player"):return
	await start(82)
	predicted=game.engine.runtime.evaluate("hexRand(JSON.parse(JSON.stringify(Hex.dispatch({op:'save'}).game)))<.5?'heads':'tails'")
	game._command({"op":"coin","call":"tails" if predicted=="heads" else "heads"});game.set_battle_active(false);game.set_battle_active(true)
	await get_tree().create_timer(1.1).timeout
	if not check(game.engine.state.phase=="opening" and game.engine.state.first==1,"Opponent-win result did not advance automatically"):return
	if DisplayServer.get_name()!="headless":
		await start(42);await get_tree().create_timer(0.5).timeout
		get_tree().root.get_texture().get_image().save_png("user://hex-opening-coin.png")
	await start(92);game._command({"op":"coin","call":"heads"})
	game.set_battle_active(false)
	if not check(not ui.coin.flipping,"Hiding battle did not cancel the flip tween"):return
	if not check(not ui.visible and ui.first_timer.is_stopped(),"Hidden battle left opening callbacks running"):return
	print("Opening coin and mulligan checks passed: ",checks)
	game.queue_free();await get_tree().create_timer(0.4).timeout;get_tree().quit()
