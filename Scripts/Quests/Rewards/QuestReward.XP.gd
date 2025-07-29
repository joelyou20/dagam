extends QuestReward
class_name QuestRewardXP

@export var amount: int

func apply_reward(player):
	PlayerManager.add_xp(amount)
