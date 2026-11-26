extends SceneTree
const Session = preload("res://Scripts/Hex/HexSession.gd")

func _initialize() -> void:
	var session := Session.new()

	assert(session.initialize(), session.last_error)
	session.runtime.evaluate(FileAccess.get_file_as_string("res://Tests/Hex/card_updates_test.js"))
	var result = JSON.parse_string(session.runtime.evaluate("JSON.stringify(runCardUpdateTests())"))

	if not result is Dictionary or result.get("checks", 0) < 25:
		push_error(str(result))
		quit(1)

		return

	print("Revised card rule checks passed: ", result.checks)
	quit()
