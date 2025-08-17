extends CanvasLayer
class_name TurnOrderUI

@onready var turn_order_item_scene = preload("res://Scenes/UI/Battle/TurnOrder/TurnOrderItem.tscn")

func update_ui():
	var turn_order_container: HBoxContainer = $TurnOrderPanel/HBoxContainer

	# wipe previous items
	for child in turn_order_container.get_children():
		child.queue_free()

	var turn_order_queue: Array[Unit] = BattleManager.get_turn_order()
	for unit in turn_order_queue:
		var item : TurnOrderItem = turn_order_item_scene.instantiate()
		# optional flags if you want tighter control
		item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		turn_order_container.add_child(item)
		item.call_deferred("set_portrait", unit.resource.portrait_texture)
