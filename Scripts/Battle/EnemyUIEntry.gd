extends HBoxContainer
class_name EnemyUIEntry

@onready var name_label: Label = $NameLabel
@onready var count_label: Label = $IndexLabel

var unit_ref: Unit = null
var _count: int = 0

@warning_ignore("unused_signal")
signal enemy_selected(unit: Unit)

func initialize(unit: Unit, count: int):
	call_deferred("set_unit_ref", unit, count)
	
func set_unit_ref(unit: Unit, count: int):
	unit_ref = unit
	name_label.text = unit.resource.name
	count_label.text = str(count + 1)
	_count = count

func increment_count():
	_count += 1
	count_label.text = str(_count)
func get_count() -> int:
	return _count

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("enemy_selected", unit_ref)
