# ItemPickup.gd
extends Interactable
@export var item: ItemResource
@export var quantity: int = 1

var moving_to_player := false
var target_node: Node3D = null
var speed := 7.5

func _on_interact():
	if not moving_to_player:
		# Add item to inventory first
		InventoryManager.add_item(item, quantity)

		# Start moving toward player
		var player = PlayerManager.get_player_node()
		target_node = player
		moving_to_player = true

		# Disable collision (optional)
		var area := $Area3D if has_node("Area3D") else null
		if area:
			area.monitoring = false

func _process(delta):
	if moving_to_player and target_node:
		var direction = (target_node.global_transform.origin - global_transform.origin)
		
		# Move toward player
		global_transform.origin += direction.normalized() * speed * delta

		if global_transform.origin.distance_to(target_node.global_transform.origin) <= 0.05:
			queue_free()
