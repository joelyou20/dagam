extends "res://addons/gut/test.gd"

const InteractionHandler = preload("res://Scripts/Utils/InteractionHandler.gd")

var handler: InteractionHandler

func before_each():
	handler = InteractionHandler.new()
	add_child(handler)

func after_each():
	handler.queue_free()
	await get_tree().process_frame

func test_block_adds_source():
	handler.block("DialogUI")
	assert_true(handler.is_blocked())

func test_unblock_removes_source():
	handler.block("Menu")
	handler.unblock("Menu")
	assert_false(handler.is_blocked())

func test_multiple_blocks_only_unblocks_one():
	handler.block("Dialog")
	handler.block("Menu")
	handler.unblock("Dialog")
	assert_true(handler.is_blocked())  # Menu still blocking

	handler.unblock("Menu")
	assert_false(handler.is_blocked())

func test_unblock_does_nothing_if_not_present():
	handler.unblock("Nonexistent")
	assert_false(handler.is_blocked())
