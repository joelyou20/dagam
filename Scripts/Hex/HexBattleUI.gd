extends UIBase
class_name HexBattleUI
@onready var battle: Control = $Panel/Battle
var _previous_scale_mode: int = -1
func _ready() -> void:
	super._ready()
	battle.return_requested.connect(on_cancel)
	ui_closed.connect(func(): battle.set_battle_active(false))
	HexManager.match_restored.connect(_on_match_restored)
func show_ui() -> void:
	if _previous_scale_mode < 0:
		_previous_scale_mode = get_window().content_scale_mode
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	super.show_ui()
	_activate_after_layout.call_deferred()
func _activate_after_layout() -> void:
	await get_tree().process_frame
	if visible: battle.set_battle_active(true)
func consume_cancel() -> bool:
	if battle.modal != null:
		battle._close()
		return true
	if HexManager.is_encounter():
		if battle.engine.state.get("winner") == null: battle.confirm_leave_encounter()
		else: BattleManager.end_battle()
		return true
	return false
func on_cancel() -> bool:
	if consume_cancel(): return true
	battle.set_battle_active(false)
	return super.on_cancel()
func _on_match_restored() -> void:
	if visible: battle.set_battle_active(true)

func hide_ui() -> void:
	_restore_resolution()
	super.hide_ui()
func _restore_resolution() -> void:
	if _previous_scale_mode >= 0:
		get_window().content_scale_mode = _previous_scale_mode
		_previous_scale_mode = -1
func _exit_tree() -> void:
	_restore_resolution()
