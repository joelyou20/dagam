extends SceneTree
const Bridge=preload("res://Scripts/Hex/HexSession.gd")
func _initialize():
 var bridge=Bridge.new()
 if not bridge.initialize(): push_error(bridge.last_error);quit(1);return
 bridge.runtime.evaluate(FileAccess.get_file_as_string("res://Tests/Hex/rules.js"))
 var regression=JSON.parse_string(bridge.runtime.evaluate("JSON.stringify(HexTests.regressions())"))
 if regression.get("passed",0)!=11: push_error(str(regression));quit(1);return
 var matches: Array=[]
 for enemy in bridge.catalog.enemies:
  for seed in [42,1337]:
   var result=JSON.parse_string(bridge.runtime.evaluate("JSON.stringify(HexTests.match("+JSON.stringify(enemy.id)+","+str(seed)+"))"))
   if result.has("error"): push_error(str(result));quit(1);return
   matches.append(result)
  print("Verified opponent ",enemy.id)
 var coverage: Array=[]
 for i in range(bridge.catalog.cards.size()):
  var id: String=bridge.catalog.cards[i].id
  var result=JSON.parse_string(bridge.runtime.evaluate("JSON.stringify(HexTests.coverage("+JSON.stringify(id)+","+str(i)+"))"))
  if result.has("error"): push_error(str(result));quit(1);return
  coverage.append(result)
  if i%20==19: print("Covered ",i+1," base cards")
 var conditionals=JSON.parse_string(bridge.runtime.evaluate("JSON.stringify(HexTests.conditionals())"))
 if not conditionals is Array: push_error(str(conditionals));quit(1);return
 var covered: Dictionary={}
 for c in coverage:
  if c.played and c.resolved: covered[c.id]=true
 for c in conditionals:
  if c.played and c.resolved: covered[c.id]=true
 if covered.size()!=160: push_error("Incomplete resolution coverage: "+str(covered.size()));quit(1);return
 var report={"played_and_resolved":covered.size(),"conditional_scenarios":conditionals,"regression_tests":regression.passed,"native_matches":matches,"coverage":coverage}
 var output:=FileAccess.open("user://native-test-results.json",FileAccess.WRITE)
 output.store_string(JSON.stringify(report,"  "))
 output.close()
 print("Native regressions: ",regression.passed,"; completed matches: ",matches.size(),"; card coverage: ",coverage.size())
 quit()
