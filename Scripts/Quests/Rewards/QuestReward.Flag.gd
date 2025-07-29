extends QuestReward
class_name QuestRewardFlag

@export var flag_name: FlagData.FlagName

func apply_reward(player):
	FlagManager.set_flag(flag_name)
