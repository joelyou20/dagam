extends SceneTree
## Render a reusable corner-matched atlas from the generated terrain artwork.
const TILE_SIZE := 128
const OUTPUT := "res://Assets/Sprites/Terrain/test_area_autotiles.png"
const TILESET := "res://Resources/Terrain/test_area_tileset.tres"

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	var viewport = SubViewport.new()

	viewport.size = Vector2i(TILE_SIZE * 8, TILE_SIZE * 8)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var rect = ColorRect.new()
	var shader_material = ShaderMaterial.new()

	shader_material.shader = load("res://Resources/Terrain/autotile_atlas.gdshader")
	shader_material.set_shader_parameter(
		"source_atlas", load("res://Assets/Sprites/Terrain/test_area.png")
	)
	shader_material.set_shader_parameter("tile_pixels", float(TILE_SIZE))
	rect.material = shader_material
	rect.size = Vector2(viewport.size)
	viewport.add_child(rect)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image = viewport.get_texture().get_image()

	assert(image.save_png(OUTPUT) == OK, "Could not save terrain atlas")
	_verify_edges(image)
	var tileset = TileSet.new()
	var atlas = TileSetAtlasSource.new()

	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tileset.add_terrain_set()
	tileset.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS)

	for name in ["Grass", "Dirt", "Water", "Stone", "Sand"]:
		var index = tileset.get_terrains_count(0)

		tileset.add_terrain(0)
		tileset.set_terrain_name(0, index, name)

	atlas.resource_scene_unique_id = "TerrainAtlas"
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = tileset.tile_size
	tileset.add_source(atlas, 0)
	var corners = [
		TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
		TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
		TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER
	]

	for index in range(64):
		var position = Vector2i(index % 8, index / 8)
		var mask = index % 16
		var terrain = 1 + index / 16

		atlas.create_tile(position)
		var tile = atlas.get_tile_data(position, 0)

		tile.terrain_set = 0
		tile.terrain = terrain if mask != 0 else 0

		for corner in range(4):
			tile.set_terrain_peering_bit(corners[corner], terrain if mask & (1 << corner) else 0)

		# A shared border can belong to a grass cell or the painted terrain cell.
		# Alternate metadata lets the editor satisfy both centre constraints.

		if mask > 0 and mask < 15:
			var alternate = atlas.create_alternative_tile(position)
			var grass_center = atlas.get_tile_data(position, alternate)

			grass_center.terrain_set = 0
			grass_center.terrain = 0

			for corner in range(4):
				grass_center.set_terrain_peering_bit(
					corners[corner], terrain if mask & (1 << corner) else 0
				)

	# Map boundaries need empty (-1) neighbours as well as terrain neighbours.
	# Reuse the solid tile's artwork with boundary-specific peering metadata.

	for terrain in range(5):
		var position = Vector2i.ZERO if terrain == 0 else Vector2i(7, (terrain - 1) * 2 + 1)

		for mask in range(15):
			var alternate = atlas.create_alternative_tile(position)
			var boundary = atlas.get_tile_data(position, alternate)

			boundary.terrain_set = 0
			boundary.terrain = terrain

			for corner in range(4):
				boundary.set_terrain_peering_bit(
					corners[corner], terrain if mask & (1 << corner) else -1
				)

	# Save an external texture reference so the resource remains small and editable.

	var external_texture = ImageTexture.new()

	external_texture.resource_scene_unique_id = "TerrainTexture"
	external_texture.take_over_path(OUTPUT)
	atlas.texture = external_texture
	assert(ResourceSaver.save(tileset, TILESET) == OK, "Could not save TileSet")
	print("Built 64 terrain autotiles; all compatible horizontal and vertical edges match")
	viewport.queue_free()
	await process_frame
	quit(0)

func _verify_edges(image: Image) -> void:
	for group in range(4):
		for first in range(16):
			for second in range(16):
				var a = Vector2i((first + group * 16) % 8, (first + group * 16) / 8) * TILE_SIZE
				var b = Vector2i((second + group * 16) % 8, (second + group * 16) / 8) * TILE_SIZE

				for offset in range(TILE_SIZE):
					if (
						((first >> 1) & 1) == (second & 1)
						and ((first >> 3) & 1) == ((second >> 2) & 1)
					):
						assert(
							(
								image.get_pixelv(a + Vector2i(TILE_SIZE - 1, offset))
								== image.get_pixelv(b + Vector2i(0, offset))
							),
							"Horizontal terrain seam"
						)

					if ((first >> 2) & 3) == (second & 3):
						assert(
							(
								image.get_pixelv(a + Vector2i(offset, TILE_SIZE - 1))
								== image.get_pixelv(b + Vector2i(offset, 0))
							),
							"Vertical terrain seam"
						)
