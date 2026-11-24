extends Control
## Vector symbols stay crisp at any board zoom; counts come from live engine state.
var effect: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var tint = Color("b7e4ff")
	var id: String = effect.get("id", "")

	if id in ["burn", "sacrifice", "no-shield", "zero-attack", "scars"]:
		tint = Color("ffac87")
	elif id in ["attack", "health"] or id.begins_with("grant-"):
		tint = Color("bdeca9")

	var center = size * 0.5
	var radius = minf(size.x, size.y) * 0.42

	draw_circle(center, radius + 2, Color(0.025, 0.035, 0.055, 0.85))
	var points: PackedVector2Array = []

	match id:
		"shield", "ward", "no-shield", "amber":
			points = PackedVector2Array(
				[
					Vector2(-0.7, -0.7),
					Vector2(0.7, -0.7),
					Vector2(0.6, 0.3),
					Vector2(0, 0.9),
					Vector2(-0.6, 0.3),
					Vector2(-0.7, -0.7)
				]
			)
		"burn":
			points = PackedVector2Array(
				[
					Vector2(0, -1),
					Vector2(0.6, -0.1),
					Vector2(0.7, 0.5),
					Vector2(0, 0.9),
					Vector2(-0.7, 0.5),
					Vector2(-0.4, -0.3),
					Vector2(0, 0.2),
					Vector2(0, -1)
				]
			)
		"stun", "delayed-stun":
			points = PackedVector2Array(
				[Vector2(0.4, -0.9), Vector2(-0.6, 0.1), Vector2(0.1, 0.1), Vector2(-0.3, 0.9)]
			)
		"attack", "zero-attack":
			points = PackedVector2Array(
				[
					Vector2(-0.65, 0.65),
					Vector2(0.65, -0.65),
					Vector2(0, -0.65),
					Vector2(0.65, -0.65),
					Vector2(0.65, 0)
				]
			)
		"invisible":
			draw_arc(center, radius * 0.8, 0, TAU, 24, tint, 1.5, true)
			draw_circle(center, radius * 0.25, tint)
		"reflect":
			draw_arc(center, radius * 0.7, -PI * 0.8, PI * 0.8, 20, tint, 2, true)
			points = PackedVector2Array([Vector2(-0.8, 0.1), Vector2(-0.55, 0.6), Vector2(0, 0.4)])
		"scars":
			for offset in [-0.5, 0.0, 0.5]:
				draw_line(
					center + Vector2(offset - 0.2, -0.7) * radius,
					center + Vector2(offset + 0.2, 0.7) * radius,
					tint,
					1.5,
					true
				)
		"pebbles":
			for offset in [-0.5, 0.0, 0.5]:
				draw_circle(
					center + Vector2(offset, absf(offset) - 0.3) * radius, radius * 0.2, tint
				)
		"control":
			draw_arc(center + Vector2(-3, 0), radius * 0.5, 0, TAU, 16, tint, 1.5, true)
			draw_arc(center + Vector2(3, 0), radius * 0.5, 0, TAU, 16, tint, 1.5, true)
		"gold":
			draw_circle(center, radius * 0.7, Color("e3bc66"))
			draw_line(center + Vector2(0, -4), center + Vector2(0, 4), Color("6b4a1f"), 2, true)
		"channel":
			for step in range(3):
				draw_arc(
					center, radius * (0.25 + step * 0.25), -PI * 0.7, PI * 0.3, 16, tint, 1.3, true
				)
		"charge":
			points = PackedVector2Array(
				[Vector2(-0.8, 0.5), Vector2(0, -0.8), Vector2(0.8, 0.5), Vector2(-0.8, 0.5)]
			)
		"health":
			points = PackedVector2Array([Vector2(-0.7, 0), Vector2(0.7, 0)])
			draw_line(
				center + Vector2(0, -radius * 0.7), center + Vector2(0, radius * 0.7), tint, 2, true
			)
		_:
			# Distinct initials cover dynamically granted abilities without font glyph dependencies.
			var letter: String = (
				effect.get("name", "?").left(2)
				if id.begins_with("grant-")
				else effect.get("name", "?").left(1)
			)

			draw_string(
				ThemeDB.fallback_font,
				center + Vector2(-5, 5),
				letter,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				14,
				tint
			)

	if not points.is_empty():
		for index in range(points.size()):
			points[index] = center + points[index] * radius * 0.8

		draw_polyline(points, tint, 1.8, true)

	if id in ["no-shield", "zero-attack"]:
		draw_line(
			center + Vector2(-radius, radius), center + Vector2(radius, -radius), tint, 1.5, true
		)

	if id in ["ward", "delayed-stun"]:
		draw_circle(center, radius * 0.25, tint)
	elif id == "amber":
		draw_line(center + Vector2(-3, 2), center + Vector2(3, 2), tint, 2, true)

	var amount = int(effect.get("amount", 0))

	if amount != 0:
		var text = str(amount)
		var position = Vector2(size.x - 7, size.y - 1)

		draw_string_outline(
			ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color.BLACK
		)
		draw_string(
			ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE
		)
