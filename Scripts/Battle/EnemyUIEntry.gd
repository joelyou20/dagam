extends HBoxContainer
class_name EnemyUIEntry

@onready var name_label: Label = $NameLabel
@onready var index_label: Label = $IndexLabel

var unit_ref: Unit = null

signal enemy_selected(unit: Unit)

func initialize(unit: Unit, index: int):
	call_deferred("set_unit_ref", unit, index)
	
func set_unit_ref(unit: Unit, index: int):
	unit_ref = unit
	name_label.text = unit.title
	index_label.text = str(index + 1)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("enemy_selected", unit_ref)
