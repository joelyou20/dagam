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
	if is_encounter() and not BattleManager.hex_encounter_active: BattleManager.resume_hex_encounter()
	return not session.state.is_empty()
func is_encounter() -> bool:
	return initialized and session.state.get("encounter") != null
func encounter_metadata() -> Dictionary:
	return session.state.get("encounter", {}) if is_encounter() else {}
func start_encounter(metadata: Dictionary, seed: int = 0) -> bool:
	if not ensure_match() or is_encounter(): return false
	var practice: Dictionary = session.request({"op":"save"})
	var result: Dictionary = session.request({"op":"new", "seed":seed if seed else int(Time.get_unix_time_from_system()), "enemy":metadata.deck_id, "encounter":metadata, "practice":practice.get("game")})
	if result.is_empty(): return false
	session.save_match()
	return true
func restore_practice() -> void:
	var saved: Dictionary = session.request({"op":"save"})
	var practice = saved.get("game", {}).get("context", {}).get("practice_game")
	var restored: Dictionary = {}
	if practice is Dictionary: restored = session.request({"op":"load", "game":practice})
	if restored.is_empty(): session.request({"op":"new", "enemy":"thornbound", "seed":int(Time.get_unix_time_from_system())})
	session.save_match()
func request(command: Dictionary) -> Dictionary:
	if not initialize(): return {}
	if is_encounter() and command.get("op") == "new":
		return {"ok":false, "state":session.state}
	return session.request(command)
func save_match() -> bool:
	return initialized and not session.state.is_empty() and session.save_match()
func save_hex() -> Dictionary:
	if not initialized or session.state.is_empty(): return {}
	return session.request({"op":"save"})
func load_hex(data: Dictionary) -> bool:
	if data.is_empty():
		if is_encounter():
			restore_practice()
			BattleManager.on_hex_state_loaded()
			match_restored.emit()
		return true
	if data.get("version") != 1 or not data.get("game") is Dictionary:
		match_error.emit("Unsupported Hex match in game save.")
		return false
	if not initialize(): return false
	var result: Dictionary = session.request({"op":"load", "game":data.game})
	if result.is_empty(): return false
	BattleManager.on_hex_state_loaded()
	session.save_match()
	match_restored.emit()
	return true
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: save_match()

var battle_ui: HexBattleUI
func is_battle_open() -> bool:
	return is_instance_valid(battle_ui) and battle_ui.visible
func open_battle() -> void:
	if not ensure_match(): return
	MenuManager.hide_menu(true)
	if not is_instance_valid(battle_ui):
		battle_ui=load("res://Scenes/Hex/HexBattleUI.tscn").instantiate()
		get_tree().root.add_child(battle_ui)
	battle_ui.show_ui()
func close_battle(force: bool = false) -> void:
	if not is_battle_open(): return
	if force: battle_ui.hide_ui()
	else: battle_ui.on_cancel()
func toggle_battle() -> void:
	if is_battle_open(): close_battle()
	else: open_battle()
