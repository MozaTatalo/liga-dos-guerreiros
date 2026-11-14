// Névoa rasteira viva: faixas longas de ruído que deslizam devagar.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
uniform vec4 cor : source_color = vec4(0.55, 0.55, 0.9, 0.22);
uniform float escala = 1.0;
uniform float vel = 0.05;
varying vec3 wp;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = vec2(wp.x * 0.35 * escala + TIME * vel, wp.y * 1.4);
	float n = ruido(p) * 0.6 + ruido(p * 2.3 + vec2(TIME * vel * 1.7, 0.0)) * 0.4;
	float alt = smoothstep(1.0, 0.0, UV.y) * smoothstep(0.0, 0.25, UV.y);
	ALBEDO = cor.rgb;
	ALPHA = smoothstep(0.35, 0.8, n) * alt * cor.a;
}
