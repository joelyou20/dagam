shader_type canvas_item;
render_mode unshaded;

uniform sampler2D source_atlas : filter_nearest, repeat_disable;
uniform float tile_pixels = 128.0;

// Each tile encodes four shared corner values (TL, TR, BL, BR). Adjacent
// tiles with matching corners evaluate the same colour along their border.
vec4 terrain_sample(vec2 tile, vec2 uv) {
	vec2 periodic_uv = 1.0 - abs(uv * 2.0 - 1.0);
	vec2 inset = 8.0 / vec2(textureSize(source_atlas, 0));
	vec2 sample_uv = (tile + mix(inset, vec2(1.0) - inset, periodic_uv)) / 4.0;
	return texture(source_atlas, sample_uv);
}

void fragment() {
	vec2 pixel = floor(UV * vec2(8.0, 8.0) * tile_pixels);
	ivec2 cell = ivec2(floor(pixel / tile_pixels));
	int index = cell.y * 8 + cell.x;
	int mask = index % 16;
	vec2 uv = mod(pixel, tile_pixels) / (tile_pixels - 1.0);
	float top = mix(float(mask & 1), float((mask >> 1) & 1), uv.x);
	float bottom = mix(float((mask >> 2) & 1), float((mask >> 3) & 1), uv.x);
	float blend = smoothstep(0.42, 0.58, mix(top, bottom, uv.y));
	vec4 grass = terrain_sample(vec2(0.0, 0.0), uv);
	vec2 other_tile = vec2(0.0, 1.0);
	if (index >= 48) { other_tile = vec2(1.0, 1.0); }
	else if (index >= 32) { other_tile = vec2(3.0, 1.0); }
	else if (index >= 16) { other_tile = vec2(0.0, 2.0); }
	vec4 other = terrain_sample(other_tile, uv);
	COLOR = mix(grass, other, blend);
}
