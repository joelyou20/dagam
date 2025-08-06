extends CanvasLayer
class_name UIBase

var interaction_handler := InteractionHandler  # Default to singleton
@export var is_hideable: bool = true
@export var should_block_interaction: bool = true

signal ui_open
signal ui_closed

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_panel_input_filter()

func _setup_panel_input_filter():
	var panel = get_node_or_null("Panel")
	if panel:
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_ui():
	visible = true
	emit_signal("ui_open")
	if should_block_interaction:
		interaction_handler.block(self.name)

func hide_ui():
	visible = false
	emit_signal("ui_closed")
	if should_block_interaction:
		interaction_handler.unblock(self.name)

func toggle():
	if visible:
		hide_ui()
	else:
		show_ui()
	
func _unhandled_input(event: InputEvent):
	if visible and event.is_action_pressed("ui_cancel"):
		on_cancel()
		get_viewport().set_input_as_handled()

func on_cancel():
	if is_hideable:
		hide_ui()
	
@warning_ignore("confusable_capture_reassignment")
static func ensure_ui(ref: UIBase, scene: PackedScene, parent: Node) -> UIBase:
	if ref == null:
		var ui = scene.instantiate() as UIBase
		parent.add_child(ui)
		ui.tree_exited.connect(func(): ref = null)
		return ui
	return ref
