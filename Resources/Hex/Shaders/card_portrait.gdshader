shader_type spatial;
render_mode unshaded;

uniform sampler2D card_art : filter_linear_mipmap_anisotropic;

void fragment() {
    vec2 portrait_uv = UV;
    portrait_uv.y = 0.17 + portrait_uv.y * 0.38;
    ALBEDO = texture(card_art, portrait_uv).rgb;
}
