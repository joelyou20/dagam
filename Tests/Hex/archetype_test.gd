extends SceneTree
const Session = preload("res://Scripts/Hex/HexSession.gd")

func _initialize() -> void:
	var session := Session.new()

	assert(session.initialize(), session.last_error)
	session.runtime.evaluate(FileAccess.get_file_as_string("res://Tests/Hex/archetype_test.js"))
	var result = JSON.parse_string(session.runtime.evaluate("JSON.stringify(runArchetypeTests())"))

	if not result is Dictionary or result.get("checks", 0) < 500:
		push_error(str(result))
		quit(1)

		return

	print("Free-play archetype checks passed: ", result.checks)
	quit()
