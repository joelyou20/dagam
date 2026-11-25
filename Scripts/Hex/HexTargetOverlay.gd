extends Control
var origin := Vector2.ZERO
var points: Array = []
var active := false

func _process(_delta: float) -> void:
	if active:
		queue_redraw()

func _draw() -> void:
	if not active:
		return

	var pulse := 0.65 + 0.2 * sin(Time.get_ticks_msec() * 0.005)
	var tint := Color(0.65, 0.92, 1.0, pulse)
	var cursor := get_local_mouse_position()
	var end := cursor

	for point in points:
		draw_arc(point, 34, 0, TAU, 40, tint, 2.5, true)

		if cursor.distance_to(point) < 60:
			end = point

	if origin.distance_to(end) < 12:
		return

	var direction := (end - origin).normalized()
	var normal := direction.orthogonal()

	draw_line(origin, end, Color(0.03, 0.08, 0.12, 0.65), 8, true)
	draw_line(origin, end, tint, 3, true)
	draw_colored_polygon(
		PackedVector2Array(
			[end, end - direction * 18 + normal * 8, end - direction * 18 - normal * 8]
		),
		tint
	)
