extends QuestReward
class_name QuestRewardItem

@export var item: ItemResource
@export var quantity: int = 1

func apply_reward():
	InventoryManager.add_item(item, quantity)
