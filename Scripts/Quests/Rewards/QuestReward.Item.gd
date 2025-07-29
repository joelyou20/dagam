extends QuestReward
class_name QuestRewardItem

@export var item_id: String
@export var quantity: int = 1

func apply_reward(player):
	PlayerManager.add_to_inventory(item_id, quantity)
