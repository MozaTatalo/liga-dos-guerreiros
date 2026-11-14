// Lodo de ectoplasma: gosma que treme, translúcida, com brilho na borda e miolo escuro.
shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_always;
uniform vec3 cor : source_color = vec3(0.12, 0.75, 0.68);
uniform vec3 miolo : source_color = vec3(0.02, 0.12, 0.16);
uniform float flash = 0.0;
uniform float tremor = 1.0;
uniform float fase = 0.0;
void vertex() {
	float w = sin(VERTEX.x * 9.0 + TIME * 5.0 + fase) * sin(VERTEX.z * 8.0 + TIME * 4.0) * sin(VERTEX.y * 7.0 + TIME * 6.0 + fase);
	VERTEX += NORMAL * w * 0.03 * tremor;
}
void fragment() {
	vec3 n = normalize(NORMAL);
	float f = pow(1.0 - clamp(dot(n, normalize(-VERTEX)), 0.0, 1.0), 2.0);
	vec3 nw = normalize((INV_VIEW_MATRIX * vec4(n, 0.0)).xyz);
	vec3 c = mix(miolo, cor, f) + cor * 0.35 * step(0.6, nw.y * 0.5 + 0.5 + nw.x * 0.2);
	float brilho = smoothstep(0.92, 0.97, dot(nw, normalize(vec3(-0.3, 0.8, 0.5))));
	c += vec3(0.85, 1.0, 1.0) * brilho;
	ALBEDO = mix(c, vec3(1.0), flash);
	ALPHA = mix(0.78, 0.97, f);
}
