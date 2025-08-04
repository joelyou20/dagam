extends Interactable
class_name InteractableMock

var interacted = false
var score = 1.0

func interact():
	interacted = true

func is_interactable() -> bool:
	return true

func get_interaction_score(_pos: Vector3, _dir: Vector3) -> float:
	return score
