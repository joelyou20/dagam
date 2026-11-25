extends Control
## Separate from creature deaths: three qualifying empty turn ends lose the match.
var count := 0

func configure(value: int) -> void:
	count = clampi(value, 0, 3)
	tooltip_text = (
		(
			"Exposure %d/3. Gain one when you end your turn empty while the opponent has a creature. "
			+ "End with a creature to reset it. Both fields empty: no increase."
		)
		% count
	)
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var filled := Color("e7b45e") if count < 2 else Color("f18078")

	draw_string(font, Vector2(0, 16), "Exposure", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

	for i in range(3):
		var center := Vector2(82 + i * 21, 11)

		draw_circle(center, 6, filled if i < count else Color("202b31"))
		draw_arc(center, 6, 0, TAU, 24, Color("d5d1c6"), 1, true)
