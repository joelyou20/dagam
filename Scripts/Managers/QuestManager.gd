extends Node
var active_quests: Dictionary = {}
var completed_quests: Array[String] = []
var initial_states: Dictionary = {}

func accept_quest(quest_name: QuestData.QuestName) -> void:
	var quest := get_quest(quest_name)

	if quest == null or active_quests.has(quest.id) or completed_quests.has(quest.id):
		return

	active_quests[quest.id] = quest
	quest.state = QuestResource.QuestState.ACTIVE
	validate_active_quest_requirements()

func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id) or completed_quests.has(quest_id):
		return

	var quest: QuestResource = active_quests[quest_id]

	quest.state = QuestResource.QuestState.COMPLETED
	completed_quests.append(quest_id)

	# Record completion first so reward flags cannot grant the rewards again.

	for reward in quest.rewards:
		if reward != null:
			reward.apply_reward()

func get_quest(quest_enum: QuestData.QuestName) -> QuestResource:
	var quest_name: String = QuestData.QuestName.keys()[quest_enum]
	var filename := quest_name.to_lower()

	if quest_enum == QuestData.QuestName.ANOTHER_DOG_TO_KICK:
		filename += "_quest"

	var quest := load("res://Resources/Quests/%s.tres" % filename) as QuestResource

	if quest != null and not initial_states.has(quest.id):
		initial_states[quest.id] = quest.state

	return quest

func is_quest_active(quest: QuestData.QuestName) -> bool:
	var id: String = QuestData.QuestName.keys()[quest]

	return active_quests.has(id) and not completed_quests.has(id)

func validate_active_quest_objectives() -> void:
	validate_active_quest_requirements()

func validate_locked_quest_requirements() -> void:
	validate_active_quest_requirements()

func validate_active_quest_requirements() -> void:
	for id in active_quests:
		if completed_quests.has(id):
			continue

		var quest: QuestResource = active_quests[id]

		if quest.requirements.is_empty() and quest.objectives.is_empty():
			continue

		if (
			quest.requirements.all(func(r): return r.validate_requirements())
			and quest.objectives.all(func(o): return o.is_complete())
		):
			complete_quest(id)

func save_quests() -> Dictionary:
	return {"active": active_quests.keys(), "completed": completed_quests.duplicate()}

func load_quests(data: Dictionary) -> void:
	active_quests.clear()
	completed_quests.clear()

	# Resource instances are cached; clear states absent from the incoming save too.

	for index in range(1, QuestData.QuestName.size()):
		var quest := get_quest(index)

		if quest != null:
			quest.state = initial_states[quest.id]

	for id in data.get("active", []):
		var index = QuestData.QuestName.get(id)

		if index == null:
			push_warning("Unknown quest ID in save data: " + str(id))
			continue

		var quest := get_quest(index)

		if quest != null:
			quest.state = QuestResource.QuestState.ACTIVE
			active_quests[id] = quest

	for id in data.get("completed", []):
		if not completed_quests.has(id):
			completed_quests.append(id)

		var index = QuestData.QuestName.get(id)

		if index != null:
			get_quest(index).state = QuestResource.QuestState.COMPLETED
