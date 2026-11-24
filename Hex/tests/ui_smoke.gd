extends SceneTree
var game
func _initialize():
 call_deferred("_run")
func _check(ok: bool,message: String) -> bool:
 if not ok:
  push_error(message)
  quit(1)
 return ok
func _run():
 game=load("res://battle.tscn").instantiate()
 root.add_child(game)
 await process_frame
 if not _check(game.engine.runtime!=null,"Engine unavailable"): return
 game.paused=false
 game._command({"op":"new","seed":42})
 game._command({"op":"coin","call":"heads"})
 var first: int=0 if game.engine.state.coin.winner==0 else 1
 game._command({"op":"first","side":first})
 if not _check(game.hand.get_child_count()==5,"Opening hand must show five cards"): return
 game._starter()
 await process_frame
 if not _check(game.modal!=null,"Starter viewer missing"): return
 game._close()
 game._pile(0,"deck")
 await process_frame
 if not _check(game.modal!=null,"Deck viewer missing"): return
 game._close()
 game._command({"op":"keep"})
 # Drive the live UI until the player can place a creature.
 for i in range(50):
  if not game._ai_can_act(): break
  game.ai_timer.stop()
  game._ai_tick()
 var g: Dictionary=game.engine.state
 if g.active==0 and g.phase=="pre":
  var played:=false
  for c in g.players[0].hand:
   var options: Array=g.handOptions.get(c.uid,[])
   if game._def(c.id).card_type=="Creature" and not options.is_empty():
    game._clicked(c,{"zone":"hand"})
    await process_frame
    if not _check(game.modal!=null,"Card selection window missing"): return
    var action=_find_button(game.modal,options[0].label)
    if not _check(action!=null,"Legal placement button missing"): return
    action.pressed.emit()
    played=true
    break
  if not _check(played,"No playable opening creature"): return
  if not _check(game.engine.state.players[0].board.any(func(c): return c!=null),"Placement failed"): return
 game._close()
 game._pause()
 if not _check(game.paused,"Save/pause failed"): return
 if not _check(game.engine.save_match(),"Save failed"): return
 game.paused=false
 game._refresh()
 await process_frame
 await process_frame
 if DisplayServer.get_name()!="headless":
  var screenshot:=root.get_texture().get_image()
  screenshot.save_png("/tmp/hex-godot-screen.png")
 print("Godot battle scene, hand, starter viewer, deck viewer and save/pause passed")
 game.queue_free()
 await create_timer(0.4).timeout
 quit()

func _find_button(node: Node,text: String):
 if node is Button and node.text==text: return node
 for child in node.get_children():
  var found=_find_button(child,text)
  if found!=null: return found
 return null
