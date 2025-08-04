extends "res://addons/gut/test.gd"

const UIBase = preload("res://Scripts/UIBase.gd")

var ui: UIBase
var fake_handler: InteractionHandlerMock

func before_each():
	fake_handler = InteractionHandlerMock.new()

	# Create a test scene tree
	var root = Node.new()

	# Create UIBase and inject a Panel child
	ui = UIBase.new()
	var panel = Panel.new()
	panel.name = "Panel"
	ui.add_child(panel)

	# Inject fake handler and initialize panel filtering
	ui.interaction_handler = fake_handler
	ui._setup_panel_input_filter()

	root.add_child(ui)
	add_child(root)

func after_each():
	if is_instance_valid(ui):
		ui.queue_free()
	await get_tree().process_frame  # Allow queued frees to finish

func test_ui_starts_invisible():
	assert_false(ui.visible)

func test_show_ui_makes_visible_and_blocks():
	ui.show_ui()
	assert_true(ui.visible)
	_assert_interaction_handler_blocked()

func test_hide_ui_makes_invisible_and_unblocks():
	ui.show_ui()
	ui.hide_ui()
	assert_false(ui.visible)
	_assert_interaction_handler_blocked()

func test_toggle_switches_state_and_calls_correct_handler():
	ui.toggle()
	assert_true(ui.visible)
	_assert_interaction_handler_blocked()

	ui.toggle()
	assert_false(ui.visible)
	_assert_interaction_handler_unblocked()

func test_on_cancel_hides_ui():
	ui.show_ui()
	ui.on_cancel()
	assert_false(ui.visible)

func test_ensure_ui_instantiates_if_null():
	var scene = PackedScene.new()
	scene.pack(ui)  # Save current ui into the packed scene
	var parent = Node.new()
	add_child(parent)

	var new_ref = null
	var result = UIBase.ensure_ui(new_ref, scene, parent)
	assert_true(result is UIBase)
	assert_true(result in parent.get_children())

func test_ensure_ui_returns_existing_if_not_null():
	var parent = Node.new()
	add_child(parent)

	var result = UIBase.ensure_ui(ui, null, parent)
	assert_eq(result, ui)

func _assert_interaction_handler_blocked():
	var block_source = "test"
	fake_handler.block(block_source)
	assert_true(fake_handler.is_blocked())
	
func _assert_interaction_handler_unblocked():
	var block_source = "test"
	fake_handler.unblock(block_source)
	assert_false(fake_handler.is_blocked())
