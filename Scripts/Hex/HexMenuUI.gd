extends UIBase
class_name HexMenuUI
@onready var battle: Control = $Panel/AspectRatioContainer/ViewportContainer/SubViewport/Battle
func _ready() -> void:
	super._ready()
	battle.return_requested.connect(on_cancel)
	ui_closed.connect(func(): battle.set_battle_active(false))
	HexManager.match_restored.connect(_on_match_restored)
func show_ui() -> void:
	super.show_ui()
	_activate_after_layout.call_deferred()
func _activate_after_layout() -> void:
	await get_tree().process_frame
	if visible: battle.set_battle_active(true)
func consume_cancel() -> bool:
	if battle.modal != null:
		battle._close()
		return true
	return false
func on_cancel() -> bool:
	if consume_cancel(): return true
	battle.set_battle_active(false)
	return super.on_cancel()
func _on_match_restored() -> void:
	if visible: battle.set_battle_active(true)
