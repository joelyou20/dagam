extends SceneTree
const Session = preload("res://Scripts/Hex/HexSession.gd")

func _initialize() -> void:
	var session := Session.new()

	assert(session.initialize(), session.last_error)
	session.runtime.evaluate(FileAccess.get_file_as_string("res://Tests/Hex/exposure_test.js"))
	var result = JSON.parse_string(session.runtime.evaluate("JSON.stringify(runExposureTests())"))

	if not result is Dictionary or result.get("checks", 0) < 35:
		push_error(str(result))
		quit(1)

		return

	print("Exposure lifecycle, save and AI checks passed: ", result.checks)
	quit()
