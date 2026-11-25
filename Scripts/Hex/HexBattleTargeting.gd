extends RefCounted
var host: Control

func _init(controller: Control) -> void:
	host = controller

	host.resolving_card = TextureRect.new()
	host.resolving_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	host.resolving_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.resolving_card.size = Vector2(112, 168)
	host.resolving_card.position = Vector2(18, 230)
	host.resolving_card.z_index = 41
	host.resolving_card.hide()
	host.target_overlay.add_child(host.resolving_card)
	host.resolving_card.mouse_entered.connect(
		func():
			if not host.targeting.is_empty():
				host._inspect(host.targeting.source)
	)
	host.resolving_card.mouse_exited.connect(func(): host.inspection.hide())

func _target_destination(option: Dictionary, op: String, uid: String) -> Dictionary:
	var task: Dictionary = option.get("task", option)
	var target_uid: String = task.get("target", task.get("take", task.get("uid", "")))
	var card: Dictionary = option.get("card") if option.get("card") != null else {}

	# Effects with two decisions select the creature before its destination.

	if task.has("slot") and task.has("target") and not option.get("_select_slot", false):
		var first = option.duplicate(true)

		first.get("task", first).erase("slot")

		return _target_destination(first, op, uid)

	if task.has("column"):
		return {"zone": "board", "side": task.get("owner", 0), "slot": task.column}

	if task.has("slot"):
		var side: int = task.get(
			"side", task.get("owner", 0 if op == "play" else host.engine.state.active)
		)
		var zone = "board"

		if op == "play":
			for held in host.engine.state.players[0].hand:
				if held.uid == uid:
					var definition = host._def(held.id)

					if definition.get("subtype", "") == "Artifact":
						zone = "artifact"

					if definition.id == "FD-024":
						side = 1
		elif not card.is_empty():
			side = card.owner

		return {"zone": zone, "side": side, "slot": task.slot}

	for side in [0, 1]:
		for zone in ["board", "artifact"]:
			var cards: Array = (
				host.engine.state.players[side].board
				if zone == "board"
				else host.engine.state.players[side].artifacts
			)

			for slot in range(cards.size()):
				if cards[slot] != null and cards[slot].uid == target_uid:
					return {"zone": zone, "side": side, "slot": slot}

	return {}

func _begin_targeting(label: String, options: Array, op: String, uid: String) -> bool:
	if options.is_empty():
		return false

	# Either member of a swap can be chosen first; retain the original engine index.

	var expanded: Array = options.duplicate(true)

	for option in options:
		var task: Dictionary = option.get("task", option)

		if task.has("target") and task.has("other"):
			var alternate: Dictionary = option.duplicate(true)
			var swapped: Dictionary = alternate.get("task", alternate)
			var first = swapped.target

			swapped.target = swapped.other
			swapped.other = first
			expanded.append(alternate)

	options = expanded
	var destinations: Array = []
	var source: Dictionary = {}

	if op == "choice" and host.engine.state.choice != null:
		source = (
			host.engine.state.choice.get("source")
			if host.engine.state.choice.get("source") != null
			else {}
		)

	if source.is_empty() and not uid.is_empty():
		for card in (
			host.engine.state.players[0].hand
			+ host.engine.state.players[0].board
			+ host.engine.state.players[0].artifacts
		):
			if card != null and card.uid == uid:
				source = card

	if source.is_empty() and op == "active":
		var source_uid: String = options[0].get("task", {}).get("source", "")

		if not source_uid.is_empty():
			for side in [0, 1]:
				for card in (
					host.engine.state.players[side].board
					+ host.engine.state.players[side].artifacts
				):
					if card != null and card.uid == source_uid:
						source = card

	for option in options:
		var destination = _target_destination(option, op, uid)

		if destination.is_empty() and option.get("task", {}).get("kind", "") != "noop":
			return false

		destinations.append(destination)

	host._close()
	_clear_targeting()
	host.targeting = {
		"label": label,
		"options": options,
		"destinations": destinations,
		"op": op,
		"uid": uid,
		"source": source
	}
	host._clear(host.controls)
	host._text(host.controls, label)

	for index in range(options.size()):
		if destinations[index].is_empty():
			host._button(host.controls, options[index].label, func(): _commit_target(index))

	if op != "choice":
		host._button(host.controls, "Cancel", _clear_targeting)

	var keys: Array = []

	for destination in destinations:
		if not destination.is_empty():
			keys.append(host.stage.key_for(destination.side, destination.slot, destination.zone))

	host.stage.target_keys = keys
	host.stage.resolving_uid = source.get("uid", "")

	if (
		not source.is_empty()
		and not is_instance_valid(host.stage.find_piece(host.stage.resolving_uid))
	):
		host.resolving_card.texture = host.Card.art(source.id)
		host.resolving_card.show()

	_update_target_overlay()

	return true

func _pick_target(_card: Dictionary, destination: Dictionary) -> void:
	var matches: Array = []

	for index in range(host.targeting.destinations.size()):
		if (
			host.targeting.destinations[index] == destination
			or (
				not host.targeting.destinations[index].is_empty()
				and host.targeting.destinations[index].zone == destination.get("zone", "")
				and host.targeting.destinations[index].side == destination.get("side", -1)
				and host.targeting.destinations[index].slot == destination.get("slot", -1)
			)
		):
			matches.append(index)

	if matches.size() == 1:
		_commit_target(matches[0])
	elif matches.size() > 1:
		var options: Array = matches.map(
			func(index): return host.targeting.options[index].duplicate(true)
		)
		var current = host.targeting.duplicate()
		var next_step := false

		for option in options:
			var task: Dictionary = option.get("task", option)

			if task.has("slot") and not option.get("_select_slot", false):
				option["_select_slot"] = true
				next_step = true
			elif task.has("other"):
				task.target = task.other
				task.erase("other")
				next_step = true

		_clear_targeting()
		host._options(
			"Choose destination" if next_step else "Choose effect",
			options,
			current.op,
			current.uid,
			next_step
		)
	else:
		host._hint("Choose a highlighted target.")

func _commit_target(index: int) -> void:
	var command = {"op": host.targeting.op, "index": host.targeting.options[index].index}

	if not host.targeting.uid.is_empty():
		command.uid = host.targeting.uid

	host._command(command)

func _clear_targeting() -> void:
	var had_targeting = not host.targeting.is_empty()

	host.targeting = {}

	if (
		had_targeting
		and is_instance_valid(host.controls)
		and host.engine != null
		and not host.engine.state.is_empty()
	):
		host._clear(host.controls)
		host._actions(host.engine.state)

	if is_instance_valid(host.stage):
		host.stage.target_keys = []
		host.stage.resolving_uid = ""

	if is_instance_valid(host.resolving_card):
		host.resolving_card.hide()

	if is_instance_valid(host.target_overlay):
		host.target_overlay.points = []
		host.target_overlay.active = false
		host.target_overlay.queue_redraw()

func _update_target_overlay() -> void:
	if host.targeting.is_empty():
		return

	var source: Dictionary = host.targeting.source

	if host.resolving_card.visible:
		var time := Time.get_ticks_msec() * 0.0055

		host.resolving_card.scale = Vector2.ONE * (1.06 + sin(time) * 0.012)
		host.resolving_card.position.y = 230 + sin(time) * 3

	var origin = host.size * Vector2(0.5, 0.8)
	var piece = host.stage.find_piece(source.get("uid", ""))

	if is_instance_valid(piece):
		origin = host.stage.project(host.stage.piece_position(source.uid))
	elif host.positions.has(source.get("uid", "")):
		origin = host.positions[source.uid].get_global_rect().get_center() - host.global_position
	elif host.resolving_card.visible:
		origin = host.resolving_card.position + host.resolving_card.size * 0.5
	elif source.get("slot") != null:
		origin = host.stage.slot_rect(source.get("owner", 0), source.slot).get_center()

	host.target_overlay.origin = origin
	host.target_overlay.points = (
		host
		. targeting
		. destinations
		. filter(func(d): return not d.is_empty())
		. map(func(d): return host.stage.slot_rect(d.side, d.slot, d.zone).get_center())
	)
	host.target_overlay.active = true
	host.target_overlay.queue_redraw()

func _reaction(response: Dictionary) -> void:
	var box = host._window("Respond to opponent's card", Vector2i(760, 550))
	var row = HBoxContainer.new()

	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)

	if response.trigger != null:
		host._card(row, response.trigger, {"zone": "inspect"}, Vector2(190, 270))

	for c in response.reactions:
		var column = VBoxContainer.new()

		row.add_child(column)
		host._card(column, c, {"zone": "inspect"}, Vector2(180, 260))
		host._button(
			column,
			"Use " + host._def(c.id).get("name", c.id),
			func():
				host._close()
				host._options(
					"Choose response", host.engine.state.handOptions.get(c.uid, []), "play", c.uid
				)
		)

	host._button(
		box,
		"Skip response",
		func():
			host._close()
			host._command({"op": "pass"})
	)

func _options(title_text: String, options: Array, op: String, uid := "", direct := true) -> void:
	if op == "play" and options.size() == 1 and _target_destination(options[0], op, uid).is_empty():
		host._close()
		host._command({"op": op, "uid": uid, "index": options[0].index})

		return

	if direct and _begin_targeting(title_text, options, op, uid):
		return

	var box = host._window(title_text)
	var scroll = ScrollContainer.new()

	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var grid = GridContainer.new()

	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	for o in options:
		var column = VBoxContainer.new()

		column.custom_minimum_size.x = 225
		grid.add_child(column)

		if o.get("card") != null:
			var c: Dictionary = o.card
			var owner = host._text(column, "YOUR CARD" if c.owner == 0 else "ENEMY'S CARD")

			owner.add_theme_color_override(
				"font_color", Color("9ac8ff") if c.owner == 0 else Color("f1a0ac")
			)
			var image = host.Card.new()

			column.add_child(image)
			image.configure(c, {}, Vector2(150, 205))
			image.inspect.connect(host._inspect)

		var b = host._button(
			column,
			o.label,
			func():
				var command = {"op": op, "index": o.index}

				if not uid.is_empty():
					command.uid = uid

				host._close()
				host._command(command)
		)

		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.y = 54

	host._button(box, "Close" if op != "choice" else "Return to board", host._close)
