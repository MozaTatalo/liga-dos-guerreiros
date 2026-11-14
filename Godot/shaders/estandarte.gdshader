// Estandarte rasgado da Ordem: tecido carmesim com barra dourada e a rosácea, ondulando no vento.
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec3 pano : source_color = vec3(0.55, 0.06, 0.13);
uniform vec3 ouro : source_color = vec3(0.86, 0.68, 0.32);
uniform float fase = 0.0;
uniform vec3 nevoa : source_color = vec3(0.13, 0.12, 0.26);
varying float sombra;
void vertex() {
	float k = 1.0 - UV.y * 0.0;
	float desce = UV.y;
	VERTEX.z += sin(TIME * 1.6 + fase + UV.y * 4.0) * 0.12 * desce;
	VERTEX.x += sin(TIME * 1.1 + fase * 0.7 + UV.y * 3.0) * 0.05 * desce;
	sombra = 0.75 + 0.25 * cos(TIME * 1.6 + fase + UV.y * 4.0);
}
float h(float x) { return fract(sin(x * 91.3) * 4375.85); }
void fragment() {
	vec2 uv = UV;
	// pontas rasgadas embaixo
	float rasgo = 0.86 + 0.1 * h(floor(uv.x * 9.0)) - abs(fract(uv.x * 9.0) - 0.5) * 0.12;
	if (uv.y > rasgo) discard;
	vec3 c = pano * (0.8 + 0.4 * (1.0 - uv.y));
	float borda = step(uv.x, 0.07) + step(0.93, uv.x) + step(uv.y, 0.06);
	c = mix(c, ouro, clamp(borda, 0.0, 1.0));
	// rosácea de oito pontas
	vec2 p = (uv - vec2(0.5, 0.36)) * vec2(1.0, 2.6);
	float r = length(p), a = atan(p.y, p.x);
	float petala = 0.18 + 0.07 * cos(a * 8.0);
	float anel = smoothstep(0.012, 0.0, abs(r - 0.22));
	c = mix(c, ouro, max(smoothstep(petala + 0.012, petala, r) * step(0.08, r) * 0.9, anel));
	c = mix(c, ouro * 1.2, smoothstep(0.07, 0.05, r));
	c *= sombra;
	ALBEDO = mix(c, nevoa, 0.35);
}
