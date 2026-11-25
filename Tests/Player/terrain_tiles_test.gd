extends SceneTree
const TILE_SIZE := 128
const CORNERS = [
	TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER
]

func _initialize() -> void:
	call_deferred("run")

func corners(index: int) -> Array:
	var result = []
	var mask = index % 16
	var terrain = index / 16 + 1

	for bit in range(4):
		result.append(terrain if mask & (1 << bit) else 0)

	return result

func run() -> void:
	var image = load("res://Assets/Sprites/Terrain/test_area_autotiles.png").get_image()
	var tileset = load("res://Resources/Terrain/test_area_tileset.tres") as TileSet

	assert(image.get_size() == Vector2i(1024, 1024))
	assert(tileset.get_terrains_count(0) == 5)
	assert(tileset.get_terrain_set_mode(0) == TileSet.TERRAIN_MODE_MATCH_CORNERS)
	var matched_edges = 0

	for first in range(64):
		var a = Vector2i(first % 8, first / 8) * TILE_SIZE
		var first_corners = corners(first)
		var tile = tileset.get_source(0).get_tile_data(Vector2i(first % 8, first / 8), 0)

		for corner in range(4):
			assert(tile.get_terrain_peering_bit(CORNERS[corner]) == first_corners[corner])

		for second in range(64):
			var b = Vector2i(second % 8, second / 8) * TILE_SIZE
			var second_corners = corners(second)

			if first_corners[1] == second_corners[0] and first_corners[3] == second_corners[2]:
				for offset in range(TILE_SIZE):
					assert(
						(
							image.get_pixelv(a + Vector2i(TILE_SIZE - 1, offset))
							== image.get_pixelv(b + Vector2i(0, offset))
						),
						"Horizontal edge mismatch"
					)

				matched_edges += 1

			if first_corners[2] == second_corners[0] and first_corners[3] == second_corners[1]:
				for offset in range(TILE_SIZE):
					assert(
						(
							image.get_pixelv(a + Vector2i(offset, TILE_SIZE - 1))
							== image.get_pixelv(b + Vector2i(offset, 0))
						),
						"Vertical edge mismatch"
					)

				matched_edges += 1

	var layer = TileMapLayer.new()

	layer.tile_set = tileset
	root.add_child(layer)
	var background: Array[Vector2i] = []

	for x in range(12):
		for y in range(12):
			background.append(Vector2i(x, y))

	layer.set_cells_terrain_connect(background, 0, 0)

	for terrain in range(1, 5):
		var cells: Array[Vector2i] = []
		var start = Vector2i(2 if terrain % 2 else 7, 2 if terrain < 3 else 7)

		for x in range(3):
			for y in range(3):
				cells.append(start + Vector2i(x, y))

		layer.set_cells_terrain_connect(cells, 0, terrain)
		assert(
			layer.get_cell_tile_data(start + Vector2i.ONE).terrain == terrain,
			"Terrain painting must select the correct interior tile"
		)

	for cell in background:
		var tile = layer.get_cell_tile_data(cell)

		assert(tile != null, "Terrain painting must not leave gaps")

		if cell.x < 11:
			var next = layer.get_cell_tile_data(cell + Vector2i.RIGHT)

			assert(
				(
					tile.get_terrain_peering_bit(CORNERS[1])
					== next.get_terrain_peering_bit(CORNERS[0])
				),
				"Painted top corners must connect"
			)
			assert(
				(
					tile.get_terrain_peering_bit(CORNERS[3])
					== next.get_terrain_peering_bit(CORNERS[2])
				),
				"Painted bottom corners must connect"
			)

		if cell.y < 11:
			var below = layer.get_cell_tile_data(cell + Vector2i.DOWN)

			assert(
				(
					tile.get_terrain_peering_bit(CORNERS[2])
					== below.get_terrain_peering_bit(CORNERS[0])
				),
				"Painted left corners must connect vertically"
			)
			assert(
				(
					tile.get_terrain_peering_bit(CORNERS[3])
					== below.get_terrain_peering_bit(CORNERS[1])
				),
				"Painted right corners must connect vertically"
			)

	layer.free()
	print(
		"Seamless terrain verified: ",
		matched_edges,
		" compatible edge pairs; all five terrains paint successfully"
	)
	quit(0)
