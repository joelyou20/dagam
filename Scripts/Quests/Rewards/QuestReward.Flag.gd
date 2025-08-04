extends QuestReward
class_name QuestRewardFlag

@export var flag_name: FlagData.FlagName

var flag_manager := FlagManager

func apply_reward():
	flag_manager.set_flag(flag_name)
