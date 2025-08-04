class_name InputMock

var action_strengths := {
	"ui_right": 0.0,
	"ui_left": 0.0,
	"ui_down": 0.0,
	"ui_up": 0.0
}

func get_action_strength(action: String) -> float:
	return action_strengths.get(action, 0.0)
