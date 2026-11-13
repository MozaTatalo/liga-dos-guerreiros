// Céu do gotico.html: degradê noturno, estrelas, lua com halo e nuvens escuras passando na frente.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;
uniform vec2 lua = vec2(0.76, 0.24);
uniform float desloc = 0.0;   // anda devagar com a câmera
uniform float chefe = 0.0;    // céu avermelhado na arena do chefe

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
void fragment() {
	vec2 uv = UV;
	float y = uv.y;
	vec3 c0 = vec3(0.02, 0.024, 0.059), c1 = vec3(0.078, 0.102, 0.2), c2 = vec3(0.173, 0.184, 0.302), c3 = vec3(0.239, 0.208, 0.314);
	vec3 c = y < 0.45 ? mix(c0, c1, y / 0.45) : (y < 0.8 ? mix(c1, c2, (y - 0.45) / 0.35) : mix(c2, c3, (y - 0.8) / 0.2));
	c = mix(c, c * vec3(1.5, 0.7, 0.75), chefe * 0.6);
	vec2 su = vec2(uv.x * 2.0 + desloc * 0.02, uv.y);
	vec2 g = floor(su * vec2(160.0, 80.0));
	float e = h21(g);
	if (e > 0.985 && y < 0.7) {
		vec2 fp = fract(su * vec2(160.0, 80.0)) - 0.5;
		c += vec3(0.81, 0.84, 1.0) * smoothstep(0.35, 0.0, length(fp)) * (0.5 + 0.5 * sin(TIME * 2.0 + e * 60.0));
	}
	vec2 d = (uv - lua) * vec2(2.0, 1.0);
	float r = length(d);
	c += vec3(0.62, 0.69, 1.0) * 0.45 * exp(-r * 7.0) + vec3(0.81, 0.85, 1.0) * 0.4 * exp(-r * 16.0);
	c = mix(c, vec3(0.9, 0.914, 0.984), smoothstep(0.052, 0.048, r));
	float n = ruido(vec2(uv.x * 4.0 + TIME * 0.01 + desloc * 0.01, uv.y * 10.0)) * ruido(vec2(uv.x * 9.0 - TIME * 0.006, uv.y * 18.0));
	float faixa = smoothstep(0.12, 0.3, uv.y) * smoothstep(0.62, 0.4, uv.y);
	c = mix(c, vec3(0.086, 0.102, 0.18), smoothstep(0.18, 0.45, n) * faixa * 0.85);
	ALBEDO = c;
}
