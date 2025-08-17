extends CanvasLayer
class_name UIBase

var interaction_handler := InteractionHandler  # Default to singleton

@export var is_hideable: bool = true
@export var should_block_interaction: bool = true
@export var participates_in_ui_stack: bool = true  # set false for non-modal overlays

# If this UI was opened from another UI, press Escape to go back to it.
var back_target: UIBase = null

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
	if visible:
		return
	visible = true
	ui_open.emit()
	if participates_in_ui_stack:
		UIManager.push(self)
	if should_block_interaction:
		interaction_handler.block(self.name)

# Helper to open as a nested screen, remembering what to go back to.
func show_as_child_of(parent_ui: UIBase):
	back_target = parent_ui
	# Hide parent so only this child is visible
	if parent_ui and parent_ui.visible:
		parent_ui.hide_ui()
	show_ui()

func hide_ui():
	if not visible:
		return
	visible = false
	# Pop first so stack stays correct even if listeners react to ui_closed
	if participates_in_ui_stack:
		UIManager.pop(self)
	ui_closed.emit()
	if should_block_interaction:
		interaction_handler.unblock(self.name)
	# Clear back link once closed
	back_target = null

func toggle():
	if visible:
		hide_ui()
	else:
		show_ui()

func _unhandled_input(event: InputEvent):
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		# If handled, stop propagation so Options doesn't open
		if on_cancel():
			get_viewport().set_input_as_handled()

# Return true if we handled cancel here (e.g., went back or closed)
func on_cancel() -> bool:
	# If this screen is nested, go back to its parent instead of closing everything.
	if back_target:
		var parent := back_target
		hide_ui()           # pops this child
		# Only show parent if it's still valid and not visible
		if is_instance_valid(parent) and not parent.visible:
			parent.show_ui()  # pushes parent back on stack
		return true

	if is_hideable:
		hide_ui()
		return true

	return false
