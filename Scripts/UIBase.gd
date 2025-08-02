extends CanvasLayer
class_name UIBase

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_ui():
	visible = true
	InteractionHandler.block("UI")

func hide_ui():
	visible = false
	InteractionHandler.unblock("UI")

func toggle():
	visible = !visible
	if visible:
		InteractionHandler.block("UI")
	else:
		InteractionHandler.unblock("UI")
	
func _unhandled_input(event: InputEvent):
	if visible and event.is_action_pressed("ui_cancel"):
		on_cancel()
		get_viewport().set_input_as_handled()

func on_cancel():
	hide_ui()
	
static func ensure_ui(ref: UIBase, scene: PackedScene, parent: Node) -> UIBase:
	if ref == null:
		var ui = scene.instantiate() as UIBase
		parent.add_child(ui)
		ui.tree_exited.connect(func(): ref = null)
		return ui
	return ref
