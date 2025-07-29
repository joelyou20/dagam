extends Resource
class_name QuestResource

enum QuestState {
	OPEN, # Has not yet been accepted, but is available to acquire
	ACTIVE, # Is ongoing
	COMPLETED, # Completed successfully
	LOCKED, # Requirements cannot be met any longer
	FAILED # Completed unsuccessfully
}

@export var id: String
@export var title: String
@export var description: String
@export var state: QuestState = QuestState.OPEN
@export var requirements: Array[QuestRequirement]
@export var objectives: Array[QuestObjective]
@export var rewards: Array[QuestReward]
