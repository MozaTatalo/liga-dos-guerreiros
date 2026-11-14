// Feixe de luz colorida que desce dos vitrais, com poeira brilhando dentro.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
uniform vec4 cor : source_color = vec4(0.7, 0.4, 1.0, 0.12);
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	float lados = smoothstep(0.0, 0.3, UV.x) * smoothstep(1.0, 0.7, UV.x);
	float desce = smoothstep(0.0, 0.15, UV.y) * (1.0 - UV.y * 0.85);
	float faixa = 0.75 + 0.25 * sin(UV.x * 18.0 + TIME * 0.4);
	vec2 g = floor(vec2(UV.x * 30.0, UV.y * 60.0 - TIME * 2.0));
	float poeira = step(0.985, h21(g)) * 1.5;
	ALBEDO = cor.rgb * cor.a * (lados * desce * faixa + poeira * lados * desce);
}
