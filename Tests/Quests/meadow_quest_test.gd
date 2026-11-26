extends Node
var checks := 0
var world

func _ready() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		get_tree().quit(1)

		return false

	checks += 1

	return true

func frames() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame

func talk(name: String) -> void:
	var npc = SceneManager.current_scene.get_node(name)
	var player = PlayerManager.get_player_node()

	player.global_position = npc.global_position + Vector3(0, 0, 0.4)
	player.get_node("Interact").interact_cooldown = 0.01
	await get_tree().create_timer(0.1).timeout
	assert(
		check(
			player.get_node("Interact").nearby_targets.has(npc),
			"NPC must register with proximity interaction: " + name
		)
	)
	assert(
		check(
			player.get_node("Interact").current_target == npc,
			"NPC must be selected as the interaction target: " + name
		)
	)
	Input.action_press("Interact")
	player.get_node("Interact").check_input()
	await frames()
	Input.action_release("Interact")
	await get_tree().process_frame

func finish_dialog() -> void:
	var ui = DialogManager.dialog_ui

	for step in range(20):
		if not ui.visible or ui.dialog_options_box.visible:
			break

		ui._fast_forward_or_next()

func choose(label: String) -> bool:
	finish_dialog()
	var matches = DialogManager.dialog_ui.options_container.get_children().filter(
		func(b): return b.text == label
	)

	assert(check(not matches.is_empty(), "Missing dialog option: " + label))

	matches[0].pressed.emit()
	await get_tree().process_frame

	return true

func run() -> void:
	world = load("res://Scenes/TerrainTest.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await get_tree().create_timer(0.3).timeout
	FlagManager.load_flags({})
	QuestManager.load_quests({})
	DialogManager.load_dialogs({})
	var area = SceneManager.current_scene
	var player = PlayerManager.player

	player.experience = 0
	player.xp_to_next_level = 1000

	for name in ["CaptainRowan", "Liora"]:
		var npc = area.get_node(name)

		assert(
			check(
				npc is NPC and npc.is_in_group("Interactable"),
				name + " must use the existing NPC interaction system"
			)
		)

		var sprite: AnimatedSprite3D = npc.get_node("Visual")

		assert(
			check(
				sprite.is_playing() and sprite.sprite_frames.get_animation_names().size() == 8,
				name + " must have four-direction idle and walk animations"
			)
		)

		assert(
			check(
				sprite.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD,
				"NPC sprites must discard transparent atlas background"
			)
		)

		for animation in sprite.sprite_frames.get_animation_names():
			assert(
				check(
					sprite.sprite_frames.get_frame_count(animation) == 8,
					"Each animation must have eight frames"
				)
			)

			for index in range(8):
				var texture = (
					sprite.sprite_frames.get_frame_texture(animation, index) as AtlasTexture
				)

				assert(
					check(
						(
							texture != null
							and Rect2(Vector2.ZERO, texture.atlas.get_size()).encloses(
								texture.region
							)
						),
						"Every NPC animation frame must remain inside its atlas"
					)
				)

	await talk("Liora")

	assert(
		check(
			(
				DialogManager.dialog_resource.npc_id == "Liora"
				and not FlagManager.is_flag_set(FlagData.FlagName.MEADOW_MET_LIORA)
			),
			"Talking out of order must not advance an unaccepted quest"
		)
	)

	finish_dialog()
	await talk("CaptainRowan")

	assert(
		check(
			(
				DialogManager.dialog_resource.npc_id == "CaptainRowan"
				and InteractionHandler.is_blocked()
			),
			"Interact must open Rowan's resource-driven dialog and block movement"
		)
	)

	assert(await choose("Perhaps later."))

	assert(
		check(
			not QuestManager.is_quest_active(QuestData.QuestName.MEADOW_ENCORE),
			"Declining must not accept the quest"
		)
	)

	await talk("CaptainRowan")

	assert(await choose("I'll check on her."))

	finish_dialog()

	assert(
		check(
			QuestManager.is_quest_active(QuestData.QuestName.MEADOW_ENCORE),
			"Accepting Rowan's request must start the existing QuestResource"
		)
	)

	var quest = QuestManager.get_quest(QuestData.QuestName.MEADOW_ENCORE)

	assert(
		check(
			quest.objectives.size() == 3 and player.experience == 0,
			"Quest must have three objectives and no early reward"
		)
	)

	await talk("Liora")
	finish_dialog()

	assert(
		check(
			quest.objectives[0].is_complete() and not quest.objectives[1].is_complete(),
			"Liora's invitation must advance only the first objective"
		)
	)

	MenuManager.set_menu(true, MenuTabs.Tab.JOURNAL)
	await get_tree().process_frame
	var journal = MenuManager.menu_ui.content_uis.Journal
	var labels = (
		journal
		. content
		. get_children()
		. filter(func(c): return c is Label)
		. map(func(c): return c.text)
	)

	assert(
		check(
			(
				labels.has("A Dance for the Meadow")
				and labels.has("✓ " + quest.objectives[0].description)
			),
			"The existing journal must show the resource title and checked objective"
		)
	)
	MenuManager.hide_menu(true)
	GameStateManager.save_game_to_file("user://meadow-quest-mid.dat")
	FlagManager.set_flag(FlagData.FlagName.MEADOW_ENCORE_FINISHED)
	QuestManager.complete_quest("MEADOW_ENCORE")
	await GameStateManager.load_game_from_file("user://meadow-quest-mid.dat")

	assert(
		check(
			(
				QuestManager.is_quest_active(QuestData.QuestName.MEADOW_ENCORE)
				and not FlagManager.is_flag_set(FlagData.FlagName.MEADOW_ENCORE_FINISHED)
				and PlayerManager.player.experience == 0
			),
			"Mid-quest world save must restore flags, objectives, dialog and XP"
		)
	)

	await talk("CaptainRowan")
	finish_dialog()

	assert(
		check(
			(
				quest.objectives[1].is_complete()
				and not "MEADOW_ENCORE" in QuestManager.completed_quests
			),
			"Delivering the invitation must not finish the whole quest"
		)
	)

	await talk("Liora")

	assert(await choose("I'd love to see your encore."))

	finish_dialog()

	assert(
		check(
			(
				"MEADOW_ENCORE" in QuestManager.completed_quests
				and PlayerManager.player.experience == 25
			),
			"The encore must complete the quest and grant exactly 25 XP"
		)
	)

	await talk("Liora")
	finish_dialog()
	await talk("CaptainRowan")
	finish_dialog()
	QuestManager.complete_quest("MEADOW_ENCORE")
	QuestManager.accept_quest(QuestData.QuestName.MEADOW_ENCORE)

	assert(
		check(
			(
				PlayerManager.player.experience == 25
				and QuestManager.completed_quests.count("MEADOW_ENCORE") == 1
			),
			"Repeating interactions or completion must not duplicate rewards"
		)
	)

	GameStateManager.save_game_to_file("user://meadow-quest-complete.dat")
	await GameStateManager.load_game_from_file("user://meadow-quest-complete.dat")

	assert(
		check(
			(
				PlayerManager.player.experience == 25
				and quest.state == QuestResource.QuestState.COMPLETED
			),
			"Loading completion must preserve XP without granting it again"
		)
	)

	FlagManager.load_flags({})
	QuestManager.load_quests({})
	DialogManager.load_dialogs({})

	assert(
		check(
			(
				not FlagManager.is_flag_set(FlagData.FlagName.MEADOW_MET_LIORA)
				and quest.state == QuestResource.QuestState.OPEN
				and DialogManager.get_active_dialog_entry("CaptainRowan").id == "offer"
			),
			"Legacy saves without the new quest must restore default flags and NPC dialog"
		)
	)

	assert(
		check(
			not HexManager.is_battle_open() and not InteractionHandler.is_blocked(),
			"Quest completion must leave exploration controls available"
		)
	)

	assert(
		check(
			(
				QuestManager.get_quest(QuestData.QuestName.ANOTHER_DOG_TO_KICK).state
				== QuestResource.QuestState.LOCKED
			),
			"Loading legacy saves must retain unrelated quests' locked defaults"
		)
	)
	DialogManager.dialog_ui.queue_free()

	if is_instance_valid(MenuManager.menu_ui):
		MenuManager.menu_ui.queue_free()

	world.queue_free()
	await get_tree().create_timer(0.4).timeout
	print("Meadow quest, sprites, dialog, save and once-only reward checks passed: ", checks)
	get_tree().quit()
