extends SceneTree
const Bridge = preload("res://Scripts/Hex/HexSession.gd")

func _initialize():
	var bridge = Bridge.new()

	if not bridge.initialize():
		push_error(bridge.last_error)
		quit(1)

		return

	bridge.runtime.evaluate(FileAccess.get_file_as_string("res://Tests/Hex/rules.js"))
	var result = JSON.parse_string(
		bridge.runtime.evaluate("JSON.stringify(HexTests.conditionals())")
	)

	if not result is Array:
		push_error(str(result))
		quit(1)

		return

	print("Conditional card scenarios passed: ", result.size())
	var report_path := "user://native-test-results.json"

	if FileAccess.file_exists(report_path):
		var report = JSON.parse_string(FileAccess.get_file_as_string(report_path))

		report.conditional_scenarios = result
		var file := FileAccess.open(report_path, FileAccess.WRITE)

		file.store_string(JSON.stringify(report, "  "))
		file.close()

	quit()
