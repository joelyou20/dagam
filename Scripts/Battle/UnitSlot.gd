extends Area3D
class_name UnitSlot

enum UnitSlotType {
	ALLY,
	ENEMY
}

@export var slot_number: int
@export var type: UnitSlotType
var node: Node = null
var unit: Unit = null

func _ready():
	node = self
	monitoring = true
	
	# Connect the input_event signal if not already connected
	if not input_event.is_connected(_input_event):
		input_event.connect(_input_event)

func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if unit != null:
				BattleManager.select_target(unit)
			else:
				print("No unit assigned to this slot")
