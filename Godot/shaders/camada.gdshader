// Camada do cenário pré-renderizada no Blender (luz, sombra e oclusão já vêm pintadas na imagem).
// Aqui só entra a névoa da distância, o tom avermelhado da arena do chefe e um tremor da luz dos braseiros.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha, fog_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform bool opaca = false;
uniform vec3 nevoa : source_color = vec3(0.16, 0.15, 0.32);
uniform float forca_nevoa = 0.0;
uniform float tom = 1.0;            // 1 = normal, menor = arena do chefe (mais escuro e vermelho)
uniform float ganho = 1.0;
uniform float saturacao = 0.7;     // o render sai azul demais; tira um pouco da cor para os personagens se destacarem
uniform vec3 tinta : source_color = vec3(1.06, 1.0, 0.93);
uniform vec3 brasas[24];
uniform int n_brasas = 0;

void fragment() {
	vec4 c = texture(tex, UV);
	vec3 col = c.rgb * ganho;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturacao) * tinta;
	// luz viva dos braseiros: a luz quente já está na imagem, aqui ela só respira
	vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float quente = 0.0;
	for (int i = 0; i < n_brasas; i++) {
		float d = length(wp.xy - brasas[i].xy);
		quente += smoothstep(4.5, 0.0, d) * (0.5 + 0.5 * sin(TIME * 9.0 + brasas[i].x * 3.1) * sin(TIME * 5.3 + brasas[i].x));
	}
	col *= 1.0 + quente * 0.12 * vec3(1.0, 0.6, 0.3);
	col = mix(col, nevoa, forca_nevoa);
	vec3 chefe = col * vec3(1.15, 0.72, 0.78);
	col = mix(chefe, col, tom);
	ALBEDO = col;
	if (!opaca) ALPHA = c.a;
}
