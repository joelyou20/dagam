extends RefCounted
## Transient battle presentation. Effects never mutate the rules engine.
const Card = preload("res://Scripts/Hex/HexCardUI.gd")

var host: Control
var announcement: Label
var announce_tween: Tween


func _init(controller: Control):
	host = controller


func clear_announcement():
	if announce_tween != null:
		announce_tween.kill()
	if is_instance_valid(announcement):
		announcement.queue_free()


func announce(message: String, persistent := false) -> void:
	if announce_tween != null:
		announce_tween.kill()
	if is_instance_valid(announcement):
		announcement.queue_free()
	var label := Label.new()
	announcement = label
	label.text = message
	label.add_theme_font_size_override("font_size", 46)
	label.add_theme_color_override("font_color", Color("f2dfb0"))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.position = Vector2(-350, -32)
	label.size = Vector2(700, 80)
	label.pivot_offset = label.size / 2
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.overlay.add_child(label)
	var tween := host.create_tween().set_parallel()
	announce_tween = tween
	tween.tween_property(label, "scale", Vector2(1.15, 1.15), 1.6)
	if not persistent:
		tween.tween_property(label, "modulate:a", 0, 0.7).set_delay(0.9)
		tween.chain().tween_callback(label.queue_free)


func play(events: Array, rects: Dictionary) -> void:
	host.stage.effects(events)
	for event in events:
		var target_data = event.get("target", {})
		var uid: String = event.get(
			"uid", target_data.get("uid", "") if target_data is Dictionary else str(target_data)
		)
		if event.kind in ["announcement", "destroy", "return"]:
			continue
		if event.kind in ["counter", "ward"]:
			_paired_effect(event)
			continue
		if event.kind == "attack":
			for key in ["attacker", "defender"]:
				_flash(event.get(key, ""), Color("ff949c"))
		elif event.kind in ["damage", "heal", "status"]:
			_flash(
				uid,
				(
					Color("ff949c")
					if event.kind == "damage"
					else Color("a2f4d0") if event.kind == "heal" else Color("eee2b0")
				)
			)
		elif rects.has(uid) and event.kind in ["destroy", "return"]:
			var ghost := TextureRect.new()
			ghost.texture = Card.art(event.get("id", ""))
			ghost.position = rects[uid].position
			ghost.size = rects[uid].size
			ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
			host.overlay.add_child(ghost)
			var tween := host.create_tween()
			tween.tween_property(ghost, "position:x", ghost.position.x + 6, 0.06)
			tween.tween_property(ghost, "position:x", ghost.position.x - 6, 0.06)
			tween.tween_property(ghost, "modulate:a", 0, 0.4)
			tween.tween_callback(ghost.queue_free)


func _flash(uid: String, color: Color) -> void:
	var target = host.positions.get(uid)
	if not is_instance_valid(target) or target.destination.get("zone") in ["board", "artifact"]:
		return
	target.modulate = color
	host.create_tween().tween_property(target, "modulate", Color.WHITE, 0.5)


func _paired_effect(event: Dictionary) -> void:
	if event.kind == "ward" and ResourceLoader.exists("res://Assets/Hex/ward.wav"):
		host.effect_sound.stream = load("res://Assets/Hex/ward.wav")
		host.effect_sound.play()
	var row := HBoxContainer.new()
	row.position = host.size / 2 - Vector2(180, 145)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.overlay.add_child(row)
	for key in ["target", "source"]:
		var c = event.get(key)
		if not c is Dictionary or not c.has("id"):
			continue
		var image := TextureRect.new()
		image.texture = Card.art(c.id)
		image.custom_minimum_size = Vector2(175, 260)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(image)
		var tween := host.create_tween()
		if event.kind == "ward" and key == "target":
			image.modulate = Color("a8e5ff")
			tween.tween_property(image, "scale", Vector2(1.05, 1.05), 0.12)
			tween.tween_property(image, "scale", Vector2.ONE, 0.12)
		elif key == "target":
			tween.tween_property(image, "position:x", 8, 0.06)
			tween.tween_property(image, "position:x", -8, 0.06)
		tween.tween_interval(
			(
				(0.7 if key == "target" else 0.25)
				if event.kind == "ward"
				else (0.25 if key == "target" else 0.6)
			)
		)
		tween.tween_property(image, "modulate:a", 0, 0.35)
	host.create_tween().tween_interval(1.3).finished.connect(row.queue_free)


func damage_number(uid: String, amount, positive: bool):
	var node = host.stage.find_piece(uid)
	if not is_instance_valid(node):
		return
	var label = Label.new()
	label.text = ("+" if positive else "−") + str(amount)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", Color("a4ffe1") if positive else Color("ffcfb5"))
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_color_override("font_outline_color", Color("152222"))
	label.position = (
		host.stage.position + host.stage.project(host.stage.piece_position(uid)) - Vector2(20, 20)
	)
	host.overlay.add_child(label)
	label.set_meta("damage_number", true)
	var tween = host.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 70, 0.75)
	tween.tween_property(label, "modulate:a", 0, 0.3).set_delay(0.45)
	tween.chain().tween_callback(label.queue_free)


func animate_hand():
	if not is_instance_valid(host.hand):
		return
	var next = {}
	for card in host.hand.get_children():
		if not card is Button or card.card.is_empty():
			continue
		var uid = card.card.uid
		next[uid] = true
		if card.has_meta("animated"):
			continue
		card.set_meta("animated", true)
		if not host.hand_snapshot.has(uid):
			var ghost = TextureRect.new()
			ghost.texture = Card.art(card.card.id)
			ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ghost.size = card.size
			host.overlay.add_child(ghost)
			ghost.position = host._pile_rect(0, "deck").position
			ghost.rotation = 0.28
			card.modulate.a = 0
			var card_ref = weakref(card)
			var tween = host.create_tween().set_parallel()
			(
				tween
				. tween_property(
					ghost, "position", card.global_position - host.global_position, 0.55
				)
				. set_trans(Tween.TRANS_CUBIC)
				. set_ease(Tween.EASE_OUT)
			)
			tween.tween_property(ghost, "rotation", 0.0, 0.5)
			tween.chain().tween_callback(
				func():
					if card_ref.get_ref() != null:
						card_ref.get_ref().modulate.a = 1
					ghost.queue_free()
			)
		card.mouse_entered.connect(
			func():
				card.z_index = 20
				card.pivot_offset = card.size / 2
				host.create_tween().tween_property(card, "scale", Vector2(1.12, 1.12), 0.14)
		)
		card.mouse_exited.connect(
			func():
				card.z_index = 0
				host.create_tween().tween_property(card, "scale", Vector2.ONE, 0.14)
				host.inspection.visible = false
		)
	host.hand_snapshot = next
