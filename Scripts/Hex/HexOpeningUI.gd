extends Control
signal action(command: Dictionary)
var coin: Control
var panel: PanelContainer
var heading: Label
var result: Label
var buttons: HBoxContainer
var first_timer: Timer
var phase := ""
var outcome: Dictionary = {}
var entrance: Tween


func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim = ColorRect.new()
	dim.color = Color(0.025, 0.055, 0.065, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 405)
	center.add_child(panel)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("152b2e")
	style.border_color = Color("cbb578")
	style.set_border_width_all(2)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0, 0, 0, 0.65)
	style.shadow_size = 24
	for edge in ["left", "top", "right", "bottom"]:
		style.set("content_margin_" + edge, 24)
	panel.add_theme_stylebox_override("panel", style)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	heading = Label.new()
	heading.text = "Who goes first?"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color("f4dda2"))
	box.add_child(heading)
	var coin_center = CenterContainer.new()
	coin_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(coin_center)
	coin = preload("res://Scripts/Hex/HexCoin.gd").new()
	coin_center.add_child(coin)
	coin.flip_finished.connect(_reveal)
	result = Label.new()
	result.text = "Call the coin"
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", 20)
	box.add_child(result)
	buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	box.add_child(buttons)
	first_timer = Timer.new()
	first_timer.one_shot = true
	first_timer.wait_time = 1.0
	first_timer.timeout.connect(_opponent_first)
	add_child(first_timer)
	hide()


func _button(text: String, command: Dictionary):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(170, 44)
	buttons.add_child(button)
	button.pressed.connect(
		func():
			for child in buttons.get_children():
				child.disabled = true
			action.emit(command)
	)


func _clear_buttons():
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()


func sync(state: Dictionary):
	var next = str(state.get("phase", ""))
	if next not in ["coin", "coinResult"]:
		dismiss()
		return
	if next == phase:
		return
	var previous = phase
	phase = next
	outcome = state.get("coin", {}).duplicate()
	first_timer.stop()
	_clear_buttons()
	if not visible:
		show()
		modulate.a = 0
		if entrance != null:
			entrance.kill()
		entrance = create_tween()
		entrance.tween_property(self, "modulate:a", 1, 0.35).set_trans(Tween.TRANS_SINE)
	if next == "coin":
		heading.text = "Who goes first?"
		result.text = "Call the coin"
		coin.show_face("heads")
		_button("Heads", {"op": "coin", "call": "heads"})
		_button("Tails", {"op": "coin", "call": "tails"})
	else:
		heading.text = "The opening toss"
		result.text = "Flipping…"
		if previous == "coin":
			coin.flip(outcome.face)
		else:
			coin.show_face(outcome.face)
			_reveal()


func _reveal():
	if phase != "coinResult" or not visible:
		return
	_clear_buttons()
	result.text = (
		str(outcome.face).capitalize()
		+ "  ·  "
		+ ("You won the toss" if outcome.winner == 0 else "Opponent goes first")
	)
	if outcome.winner == 0:
		_button("Go first", {"op": "first", "side": 0})
		_button("Go second", {"op": "first", "side": 1})
	else:
		first_timer.start()


func _opponent_first():
	if visible and phase == "coinResult" and outcome.get("winner") == 1:
		action.emit({"op": "first", "side": 1})


func dismiss():
	phase = ""
	hide()
	if is_instance_valid(coin):
		coin.stop()
	if is_instance_valid(first_timer):
		first_timer.stop()
	if entrance != null:
		entrance.kill()
