// Feixe de luz colorida que desce dos vitrais: faixas que respiram devagar e poeira brilhando dentro.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
uniform vec4 cor : source_color = vec4(0.7, 0.4, 1.0, 0.12);
float h11(float p) { return fract(sin(p * 127.1) * 43758.5453); }
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(float p) { float i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f); return mix(h11(i), h11(i + 1.0), f); }
void fragment() {
	float lados = smoothstep(0.0, 0.32, UV.x) * smoothstep(1.0, 0.68, UV.x);
	float desce = smoothstep(0.0, 0.12, UV.y) * pow(1.0 - UV.y, 1.3);
	// faixas: dois ruídos andando em sentidos opostos
	float faixa = 0.35 + 0.9 * ruido(UV.x * 7.0 + TIME * 0.06) * ruido(UV.x * 15.0 - TIME * 0.04 + 3.0);
	// poeira: pontinhos redondos que caem devagar e piscam
	vec2 g = vec2(UV.x * 16.0, UV.y * 34.0 - TIME * 0.35);
	vec2 cel = floor(g);
	vec2 centro = vec2(h21(cel), h21(cel + 7.0)) * 0.7 + 0.15;
	float pisca = 0.5 + 0.5 * sin(TIME * (1.5 + h21(cel + 3.0) * 3.0) + h21(cel) * 6.28);
	float poeira = smoothstep(0.16, 0.0, length(fract(g) - centro)) * step(0.72, h21(cel + 11.0)) * pisca * 2.2;
	ALBEDO = cor.rgb * cor.a * lados * desce * (faixa + poeira);
}
