extends SceneTree
const Session = preload("res://Scripts/Hex/HexSession.gd")

func _initialize() -> void:
	var session := Session.new()

	assert(session.initialize(), session.last_error)
	session.runtime.evaluate(FileAccess.get_file_as_string("res://Tests/Hex/interaction_test.js"))
	var result = JSON.parse_string(
		session.runtime.evaluate("JSON.stringify(runInteractionTests())")
	)

	if not result is Dictionary or result.get("checks", 0) != 13:
		push_error(str(result))
		quit(1)

		return

	print("Free-play timing and automatic trigger checks passed: ", result.checks)
	quit()
