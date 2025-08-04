extends "res://addons/gut/test.gd"

const NPC = preload("res://Scripts/NPC.gd")
const DialogManagerBase = preload("res://Scripts/Managers/DialogManager.gd")  # Adjust path as needed

var npc: NPC
var fake_dialog_manager: DialogManagerMock

func before_each():
	fake_dialog_manager = DialogManagerMock.new()
	
	# Create the NPC
	npc = NPC.new()
	npc.name = "Bob"
	npc.dialog_manager = fake_dialog_manager
	# Manually add required Area3D node
	var area := Area3D.new()
	area.name = "Area3D"
	npc.add_child(area)
	
	var entry := DialogEntry.new()
	entry.state = DialogState.State.ACTIVE

	var dialog := DialogResource.new()
	dialog.entries = [entry]

	fake_dialog_manager.dialog_registry["Bob"] = dialog
	# Connect signals if needed (optional, if your class does it in _ready)
	# area.body_entered.connect(...)

	# Add to the scene tree so _ready() runs automatically
	add_child(npc)

func after_each():
	if is_instance_valid(npc):
		npc.queue_free()

	# Remove the test dialog entry from the registry
	if DialogManager.dialog_registry.has("Bob"):
		DialogManager.dialog_registry.erase("Bob")

	# Let queued frees finish
	await get_tree().process_frame

func test_on_interact_calls_dialog_manager_with_npc_name():
	npc._on_interact()
	assert_eq(fake_dialog_manager.called_with_npc_ids, ["Bob"])
