extends Node
## Owns Hex state like the other game managers; screens only present it.
signal match_restored
signal match_error(message: String)
const Session = preload("res://Scripts/Hex/HexSession.gd")
var session: RefCounted = Session.new()
var initialized: bool = false
func initialize() -> bool:
	if initialized: return true
	initialized = session.initialize()
	if not initialized: match_error.emit(session.last_error)
	return initialized
func ensure_match() -> bool:
	if not initialize(): return false
	if session.state.is_empty() and not session.load_match():
		session.request({"op":"new", "seed":int(Time.get_unix_time_from_system()), "enemy":"thornbound"})
	return not session.state.is_empty()
func request(command: Dictionary) -> Dictionary:
	if not initialize(): return {}
	return session.request(command)
func save_match() -> bool:
	return initialized and not session.state.is_empty() and session.save_match()
func save_hex() -> Dictionary:
	if not initialized or session.state.is_empty(): return {}
	return session.request({"op":"save"})
func load_hex(data: Dictionary) -> bool:
	if data.is_empty(): return true
	if data.get("version") != 1 or not data.get("game") is Dictionary:
		match_error.emit("Unsupported Hex match in game save.")
		return false
	if not initialize(): return false
	var result: Dictionary = session.request({"op":"load", "game":data.game})
	if result.is_empty(): return false
	session.save_match()
	match_restored.emit()
	return true
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: save_match()
