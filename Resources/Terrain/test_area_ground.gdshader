shader_type spatial;

uniform sampler2D terrain_tiles : source_color, filter_nearest, repeat_disable;
uniform vec2 tile_count = vec2(28.0, 4.0);

bool dirt_corner(ivec2 corner) {
	return corner.y == 2 || corner.y == 3 || corner.x == 14 || corner.x == 15;
}

void fragment() {
	vec2 grid = UV * tile_count;
	ivec2 cell = ivec2(floor(grid));
	int mask = 0;
	if (dirt_corner(cell)) { mask |= 1; }
	if (dirt_corner(cell + ivec2(1, 0))) { mask |= 2; }
	if (dirt_corner(cell + ivec2(0, 1))) { mask |= 4; }
	if (dirt_corner(cell + ivec2(1, 1))) { mask |= 8; }
	vec2 atlas_cell = vec2(float(mask % 8), float(mask / 8));
	vec2 local_uv = (vec2(0.5) + fract(grid) * 127.0) / 128.0;
	ALBEDO = texture(terrain_tiles, (atlas_cell + local_uv) / vec2(8.0, 8.0)).rgb;
	ROUGHNESS = 1.0;
}
