extends Control
signal return_requested
const Bridge = preload("res://Scripts/Hex/HexSession.gd")
const Card = preload("res://Scripts/Hex/HexCardUI.gd")
var status_display: RefCounted
var visual_effects: RefCounted
var engine: RefCounted
var definitions: Dictionary = {}
var selected := ""
var paused := false
var ai_timer: Timer
var modal: Window
var board: Control
var stage: Control
var inspection: TextureRect
var enemy_summary: Label
var player_summary: Label
var hand_snapshot: Dictionary = {}
var hand: HBoxContainer
var controls: VBoxContainer
var subtitle: Label
var notice: Label
var preview: TextureRect
var overlay: Control
var positions: Dictionary = {}
var phase_shown := ""
var effect_sound: AudioStreamPlayer
var music: AudioStreamPlayer
var board_card_size := Vector2(140, 110)
var hand_card_size := Vector2(110, 160)
var hand_scroller: ScrollContainer
var new_game_button: Button
var utility_menu: PopupMenu
var stat_badges: Dictionary = {}
var pile_controls: Dictionary = {}
var piles_layer: Control
var opening: Control
var hint_tween: Tween
var power_displays: Array = []

func _ready() -> void:
	visual_effects = preload("res://Scripts/Hex/HexBattleEffects.gd").new(self)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	engine = HexManager.session
	paused = true
	_layout()

	for side in [0, 1]:
		var display := preload("res://Scripts/Hex/HexPowerDisplay.gd").new()

		display.position = Vector2(14, 100 if side == 1 else size.y - 285)
		display.size = Vector2(245, 110)
		display.z_index = 5
		add_child(display)
		power_displays.append(display)

	engine.fault.connect(_error)
	resized.connect(_resize_battle)
	_resize_battle.call_deferred()

func set_battle_active(active: bool) -> void:
	if not active:
		paused = true
		ai_timer.stop()
		_close()
		HexManager.save_match()
		music.stop()
		stage.set_active(false)
		opening.dismiss()

		return

	if not HexManager.ensure_match():
		_error(engine.last_error)

		return

	paused = false
	stage.set_active(true)

	for c in engine.catalog.cards:
		definitions[c.id] = c

	notice.text = (
		("Encounter · " + str(HexManager.encounter_metadata().get("name", "Enemy")))
		if HexManager.is_encounter()
		else "30 cards · Draw 5 · Six creature defeats to win"
	)
	_refresh()
	_schedule_ai()

	if engine.state.get("winner") == null and music.stream != null:
		music.play()

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var b := Button.new()

	b.text = text
	b.custom_minimum_size.y = 34
	parent.add_child(b)
	b.pressed.connect(callback)

	if text in ["Begin combat", "Finish combat", "End turn", "Return to world"]:
		b.custom_minimum_size = Vector2(172, 76)
		var style = StyleBoxFlat.new()

		style.bg_color = Color("3c715e")
		style.border_color = Color("e7ce91")
		style.set_border_width_all(3)
		style.set_corner_radius_all(36)
		b.add_theme_stylebox_override("normal", style)
		b.add_theme_font_size_override("font_size", 19)

	return b

func _text(parent: Node, text: String) -> Label:
	var label := Label.new()

	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 160
	parent.add_child(label)

	return label

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _layout() -> void:
	var app_theme = Theme.new()

	app_theme.default_font_size = 16
	var normal = StyleBoxFlat.new()

	normal.bg_color = Color("203635")
	normal.border_color = Color("9eae89")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(9)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	app_theme.set_stylebox("normal", "Button", normal)
	var hover = normal.duplicate()

	hover.bg_color = Color("3e6152")
	hover.border_color = Color("f4db9d")
	app_theme.set_stylebox("hover", "Button", hover)
	app_theme.set_stylebox("pressed", "Button", hover)
	var panel_style = StyleBoxFlat.new()

	panel_style.bg_color = Color(0.06, 0.13, 0.13, 0.94)
	panel_style.border_color = Color("6e8a74")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	app_theme.set_stylebox("panel", "PanelContainer", panel_style)
	theme = app_theme
	var background = ColorRect.new()

	background.color = Color("101e20")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	stage = preload("res://Scripts/Hex/HexBoard3D.gd").new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.offset_top = 0
	stage.offset_bottom = 0
	add_child(stage)
	board = Control.new()
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(board)
	piles_layer = Control.new()
	piles_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	piles_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(piles_layer)
	stage.impact.connect(_damage_number)
	var menu_button = MenuButton.new()

	menu_button.text = "☰"
	menu_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	menu_button.position = Vector2(-60, -55)
	menu_button.size = Vector2(42, 38)
	add_child(menu_button)
	menu_button.tooltip_text = "Battle options"
	utility_menu = menu_button.get_popup()

	for label in ["Battle deck", "Battle log", "New battle", "Concede", "Sound", "Leave battle"]:
		utility_menu.add_item(label)

	utility_menu.id_pressed.connect(_utility_action)
	subtitle = Label.new()
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	subtitle.position = Vector2(-35, 18)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)
	# Retained as an internal capability flag; new battles live in the compact menu.
	new_game_button = Button.new()
	new_game_button.visible = false
	add_child(new_game_button)
	enemy_summary = Label.new()
	enemy_summary.position = Vector2(74, 52)
	add_child(enemy_summary)
	player_summary = Label.new()
	player_summary.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	player_summary.position = Vector2(20, -40)
	add_child(player_summary)
	var turn_panel = PanelContainer.new()

	turn_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	turn_panel.position = Vector2(-202, -45)
	turn_panel.size = Vector2(184, 90)
	turn_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(turn_panel)
	controls = VBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	turn_panel.add_child(controls)
	var hand_scroll = ScrollContainer.new()

	hand_scroller = hand_scroll
	hand_scroll.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hand_scroll.offset_left = 200
	hand_scroll.offset_right = -205
	hand_scroll.offset_top = -145
	hand_scroll.offset_bottom = 24
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(hand_scroll)
	hand = HBoxContainer.new()
	hand.add_theme_constant_override("separation", -14)
	hand.alignment = BoxContainer.ALIGNMENT_CENTER
	hand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.add_child(hand)
	notice = Label.new()
	notice.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	notice.position = Vector2(20, -105)
	notice.size = Vector2(260, 55)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.add_theme_constant_override("outline_size", 5)
	notice.visible = false
	add_child(notice)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	inspection = TextureRect.new()
	inspection.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	inspection.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	inspection.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspection.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	inspection.visible = false
	inspection.z_index = 50
	overlay.add_child(inspection)
	status_display = preload("res://Scripts/Hex/HexStatusDisplay.gd").new(overlay)
	inspection.visibility_changed.connect(
		func():
			if not inspection.visible:
				status_display.tooltip.hide()
	)
	preview = inspection
	opening = preload("res://Scripts/Hex/HexOpeningUI.gd").new()
	opening.z_index = 100
	overlay.add_child(opening)
	opening.action.connect(_command)
	music = AudioStreamPlayer.new()
	music.volume_db = -24
	add_child(music)

	if ResourceLoader.exists("res://Assets/Hex/battle.mp3"):
		music.stream = load("res://Assets/Hex/battle.mp3")
		music.finished.connect(func(): music.play())

	effect_sound = AudioStreamPlayer.new()
	add_child(effect_sound)
	ai_timer = Timer.new()
	ai_timer.one_shot = true
	ai_timer.wait_time = 0.85
	ai_timer.timeout.connect(_ai_tick)
	add_child(ai_timer)

func _def(id: String) -> Dictionary:
	return definitions.get(id.replace("-FA", "").replace("-IR", ""), {})

func _inspect(c: Dictionary) -> void:
	if c.is_empty():
		return

	inspection.texture = Card.art(c.id)
	var effects: Array = c.get("statuses", [])
	var height = clampf(size.y * 0.76, 300, 760)

	if not effects.is_empty():
		height = minf(height, maxf(120, (size.x - minf(235, size.x * 0.3) - 68) * 1.5))

	inspection.size = Vector2(height * 2.0 / 3.0, height)
	var source = positions.get(c.get("uid", ""))
	var point = get_local_mouse_position()

	if is_instance_valid(source):
		point = source.get_global_rect().get_center() - global_position

	var x = point.x + 65 if point.x < size.x * 0.58 else point.x - inspection.size.x - 65

	inspection.position = Vector2(
		clampf(x, 12, size.x - inspection.size.x - 12),
		clampf(point.y - height * 0.5, 12, size.y - height - 12)
	)

	if not effects.is_empty():
		inspection.position.x = clampf(
			inspection.position.x,
			12,
			maxf(12, size.x - inspection.size.x - minf(235, size.x * 0.3) - 44)
		)

	inspection.visible = true
	status_display.show_effects(effects, Rect2(inspection.position, inspection.size), size)

func _card(parent: Node, c, dest: Dictionary, size := board_card_size, glow := false):
	var button = Card.new()

	parent.add_child(button)
	var display: Dictionary = c.duplicate() if c != null else {}

	if c != null:
		display["display_name"] = _def(c.id).get("name", c.id)

	button.configure(display, dest, size, glow)
	button.inspect.connect(_inspect)
	button.mouse_exited.connect(func(): inspection.visible = false)
	button.picked.connect(func(value): _clicked(value, dest))
	button.dropped.connect(_drop)

	if c != null:
		button.draggable = (
			dest.get("zone", "") == "hand" or (c.get("owner", -1) == 0 and c.get("ready", false))
		)
		button.is_attacker = dest.get("zone", "") == "board"
		button.tooltip_text = ""
		positions[c.uid] = button

	return button

func _refresh() -> void:
	var g: Dictionary = engine.state

	if g.is_empty():
		return

	inspection.hide()
	new_game_button.disabled = HexManager.is_encounter()
	utility_menu.set_item_disabled(2, HexManager.is_encounter())
	_clear(board)
	_clear(hand)
	_clear(controls)
	stat_badges.clear()
	_clear(piles_layer)
	pile_controls.clear()
	positions = {}
	subtitle.text = "Turn %d" % g.turn
	var display = g.duplicate(true)

	for side in [0, 1]:
		for c in display.players[side].board + display.players[side].artifacts:
			if c != null:
				c["display_name"] = _def(c.id).get("name", c.id)

	if display.field != null:
		display.field["display_name"] = _def(display.field.id).get("name", display.field.id)

	stage.sync(display)

	for side in [1, 0]:
		var p: Dictionary = g.players[side]
		var summary = enemy_summary if side == 1 else player_summary

		summary.text = ("OPPONENT" if side == 1 else "YOU") + "   %d / 6" % p.losses

		for zone in ["board", "artifact"]:
			var cards = p.board if zone == "board" else p.artifacts

			for slot in range(cards.size()):
				var rect = stage.slot_rect(side, slot, zone)
				var button = _card(
					board,
					cards[slot],
					{"zone": zone, "side": side, "slot": slot, "accept": true},
					Vector2.ZERO
				)

				button.position = rect.position
				button.size = rect.size
				button.modulate.a = 0

				if zone == "board":
					var terrain: Dictionary = p.planes[slot]

					button.tooltip_text = (
						"%s · Level %d%s"
						% [
							" / ".join(terrain.types),
							terrain.level,
							" · Locked" if terrain.get("locked", false) else ""
						]
					)

					if terrain.has("id"):
						button.tooltip_text += (
							"\n"
							+ _def(terrain.id).get("name", "")
							+ "\n"
							+ _def(terrain.id).get("rules", "")
						)

				if cards[slot] != null and cards[slot].has("hp"):
					_stat_badge(cards[slot], rect)

		for zone in ["deck", "discard"]:
			_pile_control(side, zone, p)

		if not p.exile.is_empty():
			var removed = _button(
				piles_layer, "Removed · %d" % p.exile.size(), func(): _pile(side, "exile")
			)
			var place = _pile_rect(side, "deck")

			removed.position = place.position + Vector2(0, place.size.y + 10)

	var field_rect = stage.slot_rect(0, 0, "field")
	var field = _button(
		board,
		"Battlefield",
		func():
			if g.field != null:
				_inspect(g.field)
	)

	field.position = field_rect.position
	field.size = field_rect.size
	field.modulate.a = 0

	for c in g.players[0].hand:
		_card(hand, c, {"zone": "hand"}, hand_card_size)

	for side in [0, 1]:
		power_displays[side].position.y = 100 if side == 1 else size.y - 285
		power_displays[side].configure(
			g.players[side].power,
			("Your" if side == 0 else "Enemy") + " Power · " + str(g.players[side].power.size())
		)

	_animate_hand.call_deferred()
	opening.sync(g if not paused else {})
	_actions(g)
	var key := "%s-%s-%s" % [g.tick, g.phase, g.winner]

	if key != phase_shown:
		phase_shown = key

		if g.winner != null:
			music.stop()
			var track: String = (
				"res://Assets/Hex/victory.mp3" if g.winner == 0 else "res://Assets/Hex/defeat.mp3"
			)

			if ResourceLoader.exists(track):
				effect_sound.stream = load(track)
				effect_sound.play()

			_announce("Victory" if g.winner == 0 else "Defeat" if g.winner == 1 else "Draw", true)
		elif g.phase in ["power", "pre", "combat", "post"]:
			_announce(
				(
					(
						("Your Turn\n" if g.active == 0 else "Enemy’s Turn\n")
						if g.phase == "pre"
						else ""
					)
					+ (
						{
							"pre": "Pre-Combat Phase",
							"combat": "Combat Phase",
							"post": "Post-Combat Phase"
						}
						. get(g.phase, "Power phase · Play a Plane or continue")
					)
				)
			)

	if not paused and g.choice != null and g.choice.player == 0 and modal == null:
		_options(g.choice.label, g.choice.options, "choice")
	elif (
		not paused
		and g.response != null
		and g.response.priority == 0
		and not g.response.reactions.is_empty()
		and modal == null
	):
		_reaction(g.response)

func _actions(g: Dictionary) -> void:
	if paused:
		_button(
			controls,
			"Resume",
			func():
				paused = false
				notice.text = "Game resumed."
				_refresh()
				_schedule_ai()
		)

		return

	if g.winner != null:
		_text(controls, "Victory" if g.winner == 0 else "Defeat" if g.winner == 1 else "Draw")

		if g.reason == "emptyField":
			_text(
				controls, "A turn ended with no creatures while the opponent still had creatures."
			)

		if g.reason == "roundLimit":
			_text(controls, "60 complete rounds reached.")

		if HexManager.is_encounter():
			_button(controls, "Return to world", func(): return_requested.emit())
		else:
			_button(controls, "Play again", _new_game)
	elif g.phase in ["coin", "coinResult"]:
		return
	elif g.phase == "opening":
		_button(controls, "Keep opening hand", func(): _command({"op": "keep"}))

		if not g.players[0].mulligan:
			_button(controls, "Redraw once", func(): _command({"op": "mulligan"}))
	elif g.active == 0 and g.choice == null and g.response == null:
		_button(
			controls,
			(
				{
					"power": "Main phase",
					"pre": "Begin combat",
					"combat": "Finish combat",
					"post": "End turn"
				}
				. get(g.phase, "Continue")
			),
			func(): _command({"op": "next"})
		)

		if not g.activeOptions.is_empty():
			_button(
				controls,
				"Board abilities",
				func(): _options("Board abilities", g.activeOptions, "active")
			)
	else:
		_text(
			controls,
			(
				"Opponent is thinking…"
				if g.choice == null or g.choice.player == 1
				else "Choose a target"
			)
		)

		if g.choice != null and g.choice.player == 0:
			_button(
				controls,
				"Choose target",
				func(): _options(g.choice.label, g.choice.options, "choice")
			)
		elif g.response != null and g.response.priority == 0:
			_button(controls, "Respond", func(): _reaction(g.response))

func _command(command: Dictionary) -> void:
	if paused:
		return

	if command.op == "new":
		ai_timer.stop()
		visual_effects.clear_announcement()

	var rects: Dictionary = {}

	for uid in positions:
		if is_instance_valid(positions[uid]):
			rects[uid] = positions[uid].get_global_rect()

	var result: Dictionary = HexManager.request(command)

	if result.is_empty():
		return

	if not result.get("ok", true):
		_hint("That action isn't available now.")

	selected = ""
	stage.select_attacker("", [])
	HexManager.save_match()
	_refresh()
	_effects(engine.state.get("fx", []), rects)
	engine.request({"op": "ack"})
	_schedule_ai()

func _ai_can_act() -> bool:
	if paused or engine.state.is_empty():
		return false

	var g: Dictionary = engine.state

	if g.winner != null or g.phase in ["coin", "coinResult", "opening"]:
		return false

	var side = (
		g.choice.player
		if g.choice != null
		else g.response.priority if g.response != null else g.active
	)

	return side == 1

func _schedule_ai() -> void:
	if _ai_can_act() and ai_timer.is_stopped():
		ai_timer.start()

func _ai_tick() -> void:
	if not _ai_can_act():
		return

	var rects: Dictionary = {}

	for uid in positions:
		if is_instance_valid(positions[uid]):
			rects[uid] = positions[uid].get_global_rect()

	var result: Dictionary = HexManager.request({"op": "ai"})

	if result.is_empty():
		return

	HexManager.save_match()
	_refresh()
	_effects(engine.state.get("fx", []), rects)
	engine.request({"op": "ack"})
	_schedule_ai()

func _clicked(c: Dictionary, dest: Dictionary) -> void:
	if not c.is_empty():
		_inspect(c)

	if paused or engine.state.get("winner") != null:
		return

	if dest.zone == "hand":
		var options: Array = engine.state.handOptions.get(c.uid, [])

		if options.is_empty():
			_hint(
				engine.state.get("handReasons", {}).get(
					c.uid, "This card cannot be played right now."
				)
			)

			return

		_options("Play " + _def(c.id).get("name", c.id), options, "play", c.uid)
	elif dest.zone == "board":
		if dest.side == 0 and c.get("ready", false):
			selected = c.uid
			stage.select_attacker(selected, engine.state.targets.get(selected, []))
			_hint("Choose a highlighted enemy target.")
		elif dest.side == 1 and not selected.is_empty():
			_command({"op": "attack", "attacker": selected, "target": c.get("uid", "")})

func _drop(data: Dictionary, dest: Dictionary) -> void:
	if paused:
		return

	if data.kind == "attack" and dest.zone == "board" and dest.side == 1:
		var c = engine.state.players[1].board[dest.slot]

		if c != null:
			_command({"op": "attack", "attacker": data.uid, "target": c.uid})
	elif data.kind == "hand":
		var options: Array = []
		var target = ""

		if dest.zone == "board" and engine.state.players[dest.side].board[dest.slot] != null:
			target = engine.state.players[dest.side].board[dest.slot].uid

		for o in engine.state.handOptions.get(data.uid, []):
			var played_card: Dictionary = {}

			for candidate in engine.state.players[0].hand:
				if candidate.uid == data.uid:
					played_card = _def(candidate.id)

			if (
				dest.zone == "board"
				and o.get("slot", -1) == dest.get("slot", -2)
				and (
					(played_card.get("card_type") == "Plane" and dest.side == 0)
					or (played_card.get("id") == "FD-024" and dest.side == 1)
				)
			):
				options.append(o)
			elif not target.is_empty() and o.get("target", "") == target:
				options.append(o)
			elif (
				target.is_empty()
				and dest.get("side") == 0
				and o.get("slot", -1) == dest.get("slot", -2)
			):
				var cards: Array = engine.state.players[0].hand.filter(
					func(c): return c.uid == data.uid
				)

				if not cards.is_empty():
					var d := _def(cards[0].id)

					if (
						(dest.zone == "board" and d.card_type == "Creature")
						or (dest.zone == "artifact" and d.subtype == "Artifact")
					):
						options.append(o)

		if options.size() == 1:
			_command({"op": "play", "uid": data.uid, "index": options[0].index})
		elif not options.is_empty():
			_options("Choose effect", options, "play", data.uid)
		else:
			_hint("That isn't a legal target for this card.")

func _window(title_text: String, size := Vector2i(780, 620)) -> VBoxContainer:
	_close()
	modal = Window.new()
	modal.title = title_text
	modal.size = size
	modal.min_size = Vector2i(440, 300)
	add_child(modal)
	modal.close_requested.connect(_close)
	var margin := MarginContainer.new()

	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 16)

	modal.add_child(margin)
	var box := VBoxContainer.new()

	margin.add_child(box)
	var heading := _text(box, title_text)

	heading.add_theme_font_size_override("font_size", 22)
	modal.popup_centered()

	return box

func _close() -> void:
	if inspection != null:
		inspection.visible = false

	if modal != null:
		modal.queue_free()
		modal = null

func _options(title_text: String, options: Array, op: String, uid := "") -> void:
	var box := _window(title_text)
	var scroll := ScrollContainer.new()

	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var grid := GridContainer.new()

	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	for o in options:
		var column := VBoxContainer.new()

		column.custom_minimum_size.x = 225
		grid.add_child(column)

		if o.get("card") != null:
			var c: Dictionary = o.card
			var owner := _text(column, "YOUR CARD" if c.owner == 0 else "ENEMY'S CARD")

			owner.add_theme_color_override(
				"font_color", Color("9ac8ff") if c.owner == 0 else Color("f1a0ac")
			)
			var image = Card.new()

			column.add_child(image)
			image.configure(c, {}, Vector2(150, 205))
			image.inspect.connect(_inspect)

		var b := _button(
			column,
			o.label,
			func():
				var command := {"op": op, "index": o.index}

				if not uid.is_empty():
					command.uid = uid

				_close()
				_command(command)
		)

		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.y = 54

	_button(box, "Close" if op != "choice" else "Return to board", _close)

func _reaction(response: Dictionary) -> void:
	var box := _window("Respond to opponent's card", Vector2i(760, 550))
	var row := HBoxContainer.new()

	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)

	if response.trigger != null:
		_card(row, response.trigger, {"zone": "inspect"}, Vector2(190, 270))

	for c in response.reactions:
		var column := VBoxContainer.new()

		row.add_child(column)
		_card(column, c, {"zone": "inspect"}, Vector2(180, 260))
		_button(
			column,
			"Use " + _def(c.id).get("name", c.id),
			func():
				_close()
				_options("Choose response", engine.state.handOptions.get(c.uid, []), "play", c.uid)
		)

	_button(
		box,
		"Skip response",
		func():
			_close()
			_command({"op": "pass"})
	)

func _gallery(title_text: String, cards: Array) -> void:
	var box := _window(title_text, Vector2i(900, 700))
	var scroll := ScrollContainer.new()

	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var grid := GridContainer.new()

	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	for c in cards:
		_card(grid, c, {"zone": "inspect"}, Vector2(190, 270))

	if cards.is_empty():
		_text(grid, "No cards here.")

	_button(box, "Close", _close)

func _pile(side: int, zone: String) -> void:
	if zone == "deck":
		if side == 1:
			_hint("The opponent's deck is hidden.")

			return

		var saved: Dictionary = engine.request({"op": "save"})
		var cards: Array = saved.game.players[0].deck.duplicate()

		cards.sort_custom(
			func(a, b): return _def(a.id).get("name", a.id) < _def(b.id).get("name", b.id)
		)
		_gallery("Your deck · unordered", cards)
	else:
		_gallery(("Your " if side == 0 else "Enemy ") + zone, engine.state.players[side][zone])

func _starter() -> void:
	if not engine.catalog.is_empty():
		_gallery(
			"Your battle deck · 30 cards",
			engine.state.get("playerDeck", engine.catalog.starter).map(
				func(id): return {"id": id, "owner": 0, "uid": id}
			)
		)

func _log() -> void:
	var box := _window("Battle log")
	var log := RichTextLabel.new()

	log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log.text = "\n".join(engine.state.get("log", []))
	box.add_child(log)
	_button(box, "Close", _close)

func _new_game() -> void:
	if HexManager.is_encounter():
		return

	var box := _window("New Standard battle", Vector2i(640, 380))

	_text(
		box,
		"Your selected deck is ready. Select an opponent. Starting replaces the current saved match."
	)
	var select := OptionButton.new()

	for enemy in engine.catalog.get("enemies", []):
		select.add_item(enemy.name + " · " + enemy.rank)

	box.add_child(select)
	_button(
		box,
		"Start game",
		func():
			var enemy_id: String = engine.catalog.enemies[select.selected].id

			_close()
			paused = false
			_command(
				{"op": "new", "seed": int(Time.get_unix_time_from_system()), "enemy": enemy_id}
			)
	)
	_button(box, "Cancel", _close)

func _concede() -> void:
	var box := _window("Concede this game?", Vector2i(480, 300))

	_button(
		box,
		"Concede",
		func():
			_close()
			_command({"op": "concede"})
	)
	_button(box, "Keep playing", _close)

func _pause() -> void:
	paused = true
	ai_timer.stop()
	notice.text = (
		"Game saved. You can close the window safely."
		if HexManager.save_match()
		else "Unable to save the match."
	)
	_refresh()

func _error(message: String) -> void:
	paused = true

	if notice != null:
		_hint(message)

	push_error(message)

func _exit_tree() -> void:
	paused = true

	if is_instance_valid(music):
		music.stop()
		music.stream = null

	if is_instance_valid(effect_sound):
		effect_sound.stop()
		effect_sound.stream = null

func _resize_battle() -> void:
	if not is_instance_valid(hand_scroller):
		return

	var h = clampf(size.y * 0.23, 135, 240)

	hand_scroller.offset_top = -h + 24
	hand_scroller.offset_bottom = 24
	hand_card_size = Vector2((h - 14) * 0.66, h - 14)

	if inspection != null:
		inspection.visible = false

	if engine != null and not engine.state.is_empty():
		_refresh.call_deferred()

func _animate_hand():
	visual_effects.animate_hand()

func confirm_leave_encounter() -> void:
	var box := _window("Leave this encounter?", Vector2i(520, 320))

	_text(
		box,
		"Leaving counts as a defeat. The enemy stays in the world and no victory XP is awarded."
	)
	_button(
		box,
		"Concede and return",
		func():
			_close()
			_command({"op": "concede"})
			return_requested.emit()
	)
	_button(box, "Keep playing", _close)

func _stat_badge(card: Dictionary, rect: Rect2):
	var row = Control.new()

	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.position = rect.position + Vector2(0, rect.size.y - 26)
	row.size = Vector2(rect.size.x, 34)
	board.add_child(row)

	for index in range(2):
		var circle = PanelContainer.new()

		circle.name = "Attack" if index == 0 else "Health"
		circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		circle.size = Vector2(34, 34)
		circle.position = Vector2(rect.size.x * (0.25 if index == 0 else 0.75) - 17, 0)
		var style = StyleBoxFlat.new()

		style.bg_color = Color("9c7027") if index == 0 else Color("963f49")
		style.border_color = Color("f1d59b") if index == 0 else Color("f5b5a8")
		style.set_border_width_all(2)
		style.set_corner_radius_all(17)
		style.shadow_color = Color(0, 0, 0, 0.5)
		style.shadow_size = 3
		circle.add_theme_stylebox_override("panel", style)
		row.add_child(circle)
		var label = Label.new()

		label.text = str(int(card.attack if index == 0 else card.hp))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_constant_override("outline_size", 4)
		circle.add_child(label)

	status_display.add_symbols(row, card.get("statuses", []), rect.size.x)

	row.set_meta("offset", Vector2(-rect.size.x / 2, rect.size.y / 2 - 26))
	stat_badges[card.uid] = row

func _pile_rect(side: int, zone: String) -> Rect2:
	var height = clampf(size.y * 0.20, 110, 170)
	var width = height * 2.0 / 3.0
	var x = size.x - 16 - width * 2 - 14 + (width + 14 if zone == "discard" else 0)

	return Rect2(Vector2(x, size.y * (0.14 if side == 1 else 0.66)), Vector2(width, height))

func _pile_control(side: int, zone: String, player: Dictionary):
	var rect = _pile_rect(side, zone)
	var pile = Button.new()

	pile.position = rect.position
	pile.size = rect.size
	pile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style = StyleBoxFlat.new()

	style.bg_color = Color("aaa28e")
	style.border_color = Color("d3d1b7")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.65)
	style.shadow_size = 7
	style.shadow_offset = Vector2(3, 5)
	pile.add_theme_stylebox_override("normal", style)
	pile.tooltip_text = ("Your " if side == 0 else "Opponent's ") + zone
	pile.set_meta("side", side)
	pile.set_meta("zone", zone)
	piles_layer.add_child(pile)
	pile_controls["%d-%s" % [side, zone]] = pile
	var image = TextureRect.new()

	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.offset_left = 2
	image.offset_top = 2
	image.offset_right = -2
	image.offset_bottom = -2
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.texture = (
		Card.art(player.discard.back().id)
		if zone == "discard" and not player.discard.is_empty()
		else stage.back_texture
	)

	if zone == "discard" and player.discard.is_empty():
		image.modulate = Color(0.5, 0.6, 0.6, 0.65)

	pile.add_child(image)
	var count = Label.new()

	count.text = str(int(player.deckCount if zone == "deck" else player.discard.size()))
	count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	count.offset_top = -34
	count.offset_bottom = -4
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.add_theme_font_size_override("font_size", 24)
	count.add_theme_constant_override("outline_size", 8)
	pile.add_child(count)
	pile.pressed.connect(func(): _pile(side, zone))

	if zone == "discard" and not player.discard.is_empty():
		pile.mouse_entered.connect(func(): _inspect(player.discard.back()))

	pile.mouse_exited.connect(func(): inspection.visible = false)

func _utility_action(id: int):
	match id:
		0:
			_starter()
		1:
			_log()
		2:
			_new_game()
		3:
			_concede()
		4:
			AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))
		5:
			return_requested.emit()

func _process(_delta: float):
	if paused or not is_instance_valid(stage):
		return

	for uid in stat_badges:
		var piece = stage.find_piece(uid)
		var badge = stat_badges[uid]

		if is_instance_valid(piece) and is_instance_valid(badge):
			badge.position = stage.project(stage.piece_position(uid)) + badge.get_meta("offset")

func _hint(message: String):
	if hint_tween != null:
		hint_tween.kill()

	notice.text = message
	notice.visible = true
	notice.modulate.a = 1
	hint_tween = create_tween()
	hint_tween.tween_interval(2.3)
	hint_tween.tween_property(notice, "modulate:a", 0, 0.3)
	hint_tween.tween_callback(notice.hide)

func _announce(message: String, persistent := false) -> void:
	visual_effects.announce(message, persistent)

func _effects(events: Array, rects: Dictionary) -> void:
	visual_effects.play(events, rects)

func _damage_number(uid: String, amount, positive: bool):
	visual_effects.damage_number(uid, amount, positive)
