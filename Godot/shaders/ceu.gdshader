// Céu noturno pintado: degradê violeta, estrelas que cintilam, lua grande com crateras e halo,
// e nuvens em camadas com a borda acesa pela lua.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;
uniform vec2 lua = vec2(0.74, 0.22);
uniform float desloc = 0.0;
uniform float chefe = 0.0;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float s = 0.0, a = 0.5; for (int i = 0; i < 4; i++) { s += ruido(p) * a; p *= 2.03; a *= 0.5; } return s; }
void fragment() {
	vec2 uv = UV;
	float y = uv.y;
	vec3 c0 = vec3(0.025, 0.02, 0.07), c1 = vec3(0.09, 0.07, 0.24), c2 = vec3(0.24, 0.15, 0.38), c3 = vec3(0.42, 0.22, 0.42);
	vec3 c = y < 0.4 ? mix(c0, c1, y / 0.4) : (y < 0.78 ? mix(c1, c2, (y - 0.4) / 0.38) : mix(c2, c3, (y - 0.78) / 0.22));
	c = mix(c, c * vec3(1.6, 0.6, 0.6), chefe * 0.7);
	vec2 su = vec2(uv.x * 2.0 + desloc * 0.02, uv.y);
	vec2 g = floor(su * vec2(170.0, 85.0));
	float e = h21(g);
	if (e > 0.982 && y < 0.72) {
		vec2 fp = fract(su * vec2(170.0, 85.0)) - 0.5;
		float tw = 0.5 + 0.5 * sin(TIME * 2.5 + e * 80.0);
		vec3 ce = mix(vec3(0.8, 0.85, 1.0), vec3(1.0, 0.8, 0.95), fract(e * 37.0));
		c += ce * (smoothstep(0.3, 0.0, length(fp)) + smoothstep(0.06, 0.0, abs(fp.x)) * smoothstep(0.5, 0.0, abs(fp.y)) * 0.4 * tw) * tw;
	}
	vec2 d = (uv - lua) * vec2(2.0, 1.0);
	float r = length(d);
	c += vec3(0.55, 0.5, 1.0) * 0.55 * exp(-r * 5.0) + vec3(0.85, 0.85, 1.0) * 0.5 * exp(-r * 14.0);
	c += vec3(0.7, 0.6, 1.0) * 0.25 * smoothstep(0.012, 0.0, abs(r - 0.1));
	float disco = smoothstep(0.072, 0.068, r);
	vec2 q = d / 0.07;
	float crat = fbm(q * 2.6 + 3.0);
	vec3 lc = mix(vec3(0.98, 0.97, 1.0), vec3(0.72, 0.72, 0.9), smoothstep(0.45, 0.7, crat));
	lc *= 0.82 + 0.18 * smoothstep(1.0, -0.6, q.x + q.y * 0.4);
	c = mix(c, lc, disco);
	for (int k = 0; k < 3; k++) {
		float fk = float(k);
		vec2 np = vec2(uv.x * (2.2 + fk) + TIME * (0.004 + fk * 0.003) + desloc * (0.006 + fk * 0.006), uv.y * (5.0 + fk * 2.0) + fk * 3.1);
		float n = fbm(np);
		float faixa = smoothstep(0.1 + fk * 0.12, 0.3 + fk * 0.12, uv.y) * smoothstep(0.62 + fk * 0.1, 0.4 + fk * 0.1, uv.y);
		float m = smoothstep(0.48, 0.66, n) * faixa;
		float borda = smoothstep(0.48, 0.55, n) - smoothstep(0.55, 0.66, n);
		vec3 nc = mix(vec3(0.09, 0.06, 0.2), vec3(0.16, 0.1, 0.3), fk * 0.5);
		c = mix(c, nc, m * 0.92);
		c += vec3(0.55, 0.5, 0.95) * borda * faixa * 0.35 * exp(-r * 1.6);
	}
	ALBEDO = c;
}
