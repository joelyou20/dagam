extends RefCounted
signal fault(message: String)
var runtime: RefCounted
var state: Dictionary = {}
var catalog: Dictionary = {}
var last_error := ""
const SAVE := "user://hex-match-v1.json"
func initialize() -> bool:
 if not ClassDB.class_exists("HexRuntime"):
  last_error="Build native/hex_runtime first; see Hex/README.md."
  return false
 runtime=ClassDB.instantiate("HexRuntime")
 var result: String=runtime.evaluate(FileAccess.get_file_as_string("res://engine/battle.js"))
 if result!="ready":
  last_error=result
  return false
 catalog=request({"op":"catalog"})
 return not catalog.is_empty()
func request(command: Dictionary) -> Dictionary:
 var result=JSON.parse_string(runtime.evaluate("JSON.stringify(Hex.dispatch("+JSON.stringify(command)+"))"))
 if not result is Dictionary or result.has("error"):
  last_error=str(result.get("error","Invalid response")) if result is Dictionary else "Invalid response"
  fault.emit(last_error)
  return {}
 if result.get("state")!=null: state=result.state
 return result
func save_match() -> bool:
 var saved=request({"op":"save"})
 if not saved.has("game"): return false
 var payload:=JSON.stringify(saved)
 var file:=FileAccess.open(SAVE+".tmp",FileAccess.WRITE)
 if file==null: return false
 file.store_string(JSON.stringify({"version":1,"payload":payload,"checksum":payload.sha256_text()}))
 file.close()
 var dir:=DirAccess.open("user://")
 if dir.file_exists("hex-match-v1.json"): dir.rename("hex-match-v1.json","hex-match-v1.backup.json")
 return dir.rename("hex-match-v1.json.tmp","hex-match-v1.json")==OK
func load_match() -> bool:
 if not FileAccess.file_exists(SAVE): return false
 var envelope=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
 if not envelope is Dictionary or envelope.get("version")!=1:
  last_error="Unsupported saved match."
  return false
 var payload: String=envelope.get("payload","")
 if payload.sha256_text()!=envelope.get("checksum",""):
  last_error="Saved match damaged; backup preserved."
  return false
 var saved=JSON.parse_string(payload)
 if not saved is Dictionary or not saved.has("game"): return false
 return not request({"op":"load","game":saved.game}).is_empty()
