extends Control
var markers: Array = []
var warning: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	for side in [0, 1]:
		var display := preload("res://Scripts/Hex/HexExposureDisplay.gd").new()

		if side == 0:
			display.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)

		display.position = Vector2(20, -42) if side == 0 else Vector2(74, 76)
		display.size = Vector2(145, 24)
		add_child(display)
		markers.append(display)

	warning = Label.new()
	warning.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	warning.position = Vector2(20, -213)
	warning.size = Vector2(175, 84)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.add_theme_font_size_override("font_size", 14)
	warning.add_theme_color_override("font_color", Color("ffb3a6"))
	warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warning.hide()
	add_child(warning)

func configure(state: Dictionary) -> void:
	for side in [0, 1]:
		markers[side].configure(int(state.players[side].get("exposure", 0)))

	warning.visible = (
		state.winner == null
		and int(state.players[0].get("exposure", 0)) == 2
		and state.players[1].board.any(func(c): return c != null)
	)
	warning.text = (
		"End your turn with a creature in play to avoid defeat."
		if state.active == 0
		else "End your next turn with a creature in play to avoid defeat."
	)
