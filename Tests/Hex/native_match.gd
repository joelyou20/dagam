extends SceneTree
const Bridge=preload("res://Scripts/Hex/HexSession.gd")
func _initialize():
 var bridge=Bridge.new()
 assert(bridge.initialize(),bridge.last_error)
 assert(bridge.catalog.cards.size()==160)
 assert(bridge.catalog.starter.size()==20)
 assert(bridge.request({"op":"new","seed":42}).state.phase=="coin")
 bridge.request({"op":"coin","call":"heads"})
 var side: int=0 if bridge.state.coin.winner==0 else 1
 bridge.request({"op":"first","side":side})
 assert(bridge.state.players[0].hand.size()==5)
 bridge.request({"op":"keep"})
 var result: String=bridge.runtime.evaluate("(()=>{let n=0;while(Hex.dispatch({op:'view'}).state.winner===null&&n++<1000){const g=Hex.dispatch({op:'save'}).game;const side=g.choice?.player??g.stack.at(-1)?.priority??g.active;if(!hexAscendedStep(g,side))throw Error('no legal move');}return JSON.stringify({steps:n,winner:Hex.dispatch({op:'view'}).state.winner});})()")
 print(result)
 var parsed=JSON.parse_string(result)
 if not parsed is Dictionary or parsed.get("winner")==null: push_error(result);quit(1);return
 assert(bridge.save_match())
 var restored=Bridge.new()
 assert(restored.initialize())
 assert(restored.load_match(),restored.last_error)
 assert(restored.state.winner==bridge.request({"op":"view"}).state.winner)
 print("Native full match and save/restore passed")
 quit()
