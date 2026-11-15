shader_type canvas_item;
render_mode blend_add, unshaded;
// Energia desenhada (cortes, ondas, pilares, bolas de fogo): um ruído corre ao longo da forma,
// o miolo fica branco e a borda se desfaz conforme o efeito envelhece. Anda em degraus, como efeito desenhado à mão.
// UV.x = ao longo da forma (pode passar de 1). UV.y = 0..1 de uma borda à outra (0.5 é o miolo).
// Cor do vértice = cor da energia. Alfa do vértice = "vida": 1 inteira, 0 desfeita.
uniform sampler2D ruido : repeat_enable, filter_linear;
uniform float passo = 14.0;

void fragment() {
	float t = floor(TIME * passo) / passo;
	vec4 v = COLOR;
	float n1 = texture(ruido, vec2(UV.x * 0.55 - t * 1.1, UV.y * 0.45 + t * 0.13)).r;
	float n2 = texture(ruido, vec2(UV.x * 1.3 - t * 2.3, UV.y * 0.9 - t * 0.21) + vec2(0.37, 0.61)).r;
	float n = n1 * 0.62 + n2 * 0.38;
	float perfil = sin(clamp(UV.y, 0.0, 1.0) * 3.14159265);
	float forma = perfil * (0.35 + 1.05 * n);
	float corte = 1.0 - v.a;
	float a = smoothstep(corte, corte + 0.16, forma) * smoothstep(0.0, 0.1, v.a);
	float miolo = smoothstep(1.0, 1.4, forma) * v.a;
	vec3 cor = mix(v.rgb * mix(0.62, 1.0, perfil), vec3(1.0), miolo * 0.6);
	COLOR = vec4(cor, a * (0.3 + 0.7 * perfil));
}
