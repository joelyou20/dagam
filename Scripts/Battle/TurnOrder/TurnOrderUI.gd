extends CanvasLayer
class_name TurnOrderUI

@onready var turn_order_item_scene = preload("res://Scenes/UI/Battle/TurnOrder/TurnOrderItem.tscn")

signal turn_order_changed

var _turn_order_manager: TurnOrderManager
var _unit_manager: UnitManager

func _ready():
	_turn_order_manager = TurnOrderManager
	_unit_manager = UnitManager
	turn_order_changed.connect(update_ui)

func update_ui():
	var turn_order_container: HBoxContainer = $TurnOrderPanel/HBoxContainer

	# wipe previous items
	for child in turn_order_container.get_children():
		child.queue_free()

	for id in _turn_order_manager.turn_order_queue:
		var item : TurnOrderItem = turn_order_item_scene.instantiate()
		# optional flags if you want tighter control
		item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		turn_order_container.add_child(item)
		
		var unit: Unit = _unit_manager.find_unit_by_id(id)
		if (!unit):
			return
		
		item.call_deferred("set_portrait", unit.resource.portrait_texture)
