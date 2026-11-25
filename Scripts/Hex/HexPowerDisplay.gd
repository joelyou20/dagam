extends Control
## Individual split spheres remain visible because each pays only one colour.
const COLORS := {
	"Earth": Color("338943"),
	"Fire": Color("d33a35"),
	"Water": Color("237bc1"),
	"Sky": Color("e8c83d"),
	"Dark": Color("171923"),
	"Light": Color("f3f1e8")
}
var spheres: Array = []
var caption := ""

func configure(value: Array, title: String) -> void:
	spheres = value
	caption = title
	tooltip_text = (
		"Power lasts until your next Power phase. "
		+ "Each split sphere pays either colour once. Grey card costs accept any colour."
	)
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font

	draw_string(font, Vector2(0, 16), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

	for i in range(spheres.size()):
		var center := Vector2(14 + (i % 8) * 30, 37 + floori(i / 8.0) * 30)
		var types: Array = spheres[i]

		for part in range(types.size()):
			var polygon := PackedVector2Array([center])

			for step in range(17):
				var angle := -PI / 2 + TAU * (part + step / 16.0) / types.size()

				polygon.append(center + Vector2(cos(angle), sin(angle)) * 12)

			draw_colored_polygon(polygon, COLORS.get(types[part], Color.GRAY))

		draw_arc(center, 12, 0, TAU, 32, Color("e5decb"), 1.5, true)
