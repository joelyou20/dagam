shader_type spatial;
uniform sampler2D terrain_tiles : source_color, filter_nearest, repeat_disable;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

int terrain_at(vec2 point) {
	if (distance((point - vec2(-3.5, -2.2)) * vec2(0.9, 1.2), vec2(0.0)) < 1.15) {
		return 2;
	}
	bool main_path = abs(point.x) <= 0.5;
	bool market_path = point.x >= -3.5 && point.x <= 0.0 && point.y >= 1.0 && point.y <= 1.5;
	bool clearing = point.x >= 0.0 && point.x <= 2.0 && point.y >= -3.0 && point.y <= -1.5;
	return main_path || market_path || clearing ? 1 : 0;
}

void fragment() {
	vec2 grid = world_position.xz * 2.0;
	vec2 cell = floor(grid);
	int a = terrain_at(cell * 0.5);
	int b = terrain_at((cell + vec2(1.0, 0.0)) * 0.5);
	int c = terrain_at((cell + vec2(0.0, 1.0)) * 0.5);
	int d = terrain_at((cell + vec2(1.0, 1.0)) * 0.5);
	int terrain = max(max(a, b), max(c, d));
	int mask = (a == terrain ? 1 : 0) | (b == terrain ? 2 : 0) | (c == terrain ? 4 : 0) | (d == terrain ? 8 : 0);
	int index = terrain == 0 ? 0 : (terrain - 1) * 16 + mask;
	vec2 atlas_cell = vec2(float(index % 8), float(index / 8));
	vec2 local_uv = (vec2(0.5) + fract(grid) * 127.0) / 128.0;
	ALBEDO = texture(terrain_tiles, (atlas_cell + local_uv) / 8.0).rgb;
	ROUGHNESS = 1.0;
}
