shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

void fragment() {
    vec2 point = abs(UV * 2.0 - 1.0);
    float distance_to_edge = max(point.y, point.x * 0.8660254 + point.y * 0.5);
    ALBEDO = vec3(0.0);
    ALPHA = (1.0 - smoothstep(0.72, 1.0, distance_to_edge)) * 0.42;
}
