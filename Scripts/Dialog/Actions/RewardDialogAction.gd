extends DialogAction
class_name RewardDialogAction

@export var reward_item: ItemResource
@export var quantity: int = 1

func execute():
	InventoryManager.add_item(reward_item, quantity)
	print("Item received as reward: " + reward_item.name)
