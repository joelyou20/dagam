extends Node
class_name TurnOrderUI

func update_ui():
	var turn_order_container: HBoxContainer = $HBoxContainer
	var turn_order_queue: Array[Unit] = BattleManager.get_turn_order()
	for unit in turn_order_queue:
		var portrait: TextureRect = TextureRect.new()
		#portrait.texture = unit.resource.visual_scene.instantiate()
		#turn_order_container.add_child(portrait)
