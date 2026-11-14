// Cel-shading igual ao do three.js (MeshToonMaterial com mapa de degraus).
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool tem_tex = false;
uniform vec4 cor : source_color = vec4(1.0);
uniform vec2 uv_escala = vec2(1.0);
uniform vec2 uv_desloc = vec2(0.0);
// degraus de luz (0..1); n = quantos estão em uso
uniform vec4 degraus = vec4(0.275, 0.53, 0.784, 1.0);
uniform int n_degraus = 4;
uniform vec3 luz_chave = vec3(0.45, 0.6, 0.66);
uniform vec3 cor_chave : source_color = vec3(1.0, 0.95, 0.9);
uniform vec3 luz_contra = vec3(-0.5, 0.55, -0.66);
uniform vec3 cor_contra : source_color = vec3(0.56, 0.66, 1.0);
uniform vec3 ceu : source_color = vec3(0.56, 0.63, 0.85);
uniform vec3 chao : source_color = vec3(0.1, 0.08, 0.13);
uniform float forca_chave = 0.78;
uniform float forca_contra = 0.45;
uniform float forca_amb = 0.4;
uniform float brilho = 1.0;
uniform bool recorte = false;     // manto rasgado do espectro (alfa da textura)
uniform float flash = 0.0;         // pisca branco ao levar golpe
uniform vec3 cor_aro : source_color = vec3(0.62, 0.6, 1.0);   // luz de contorno da lua
uniform float forca_aro = 0.5;
uniform vec3 luz_quente = vec3(0.0);  // direção (no mundo) da luz do braseiro mais perto
uniform float forca_quente = 0.0;
uniform vec3 cor_quente : source_color = vec3(1.0, 0.55, 0.22);
uniform float onda = 0.0;             // barra do manto ondulando (espectros)
uniform vec3 emissao : source_color = vec3(0.0);

float degrau(float d) {
	float k = clamp(d * 0.5 + 0.5, 0.0, 0.999);
	int i = int(floor(k * float(n_degraus)));
	return i == 0 ? degraus.x : (i == 1 ? degraus.y : (i == 2 ? degraus.z : degraus.w));
}

void vertex() {
	if (onda > 0.0) {
		float k = clamp(1.0 - (VERTEX.y + 0.05) / 0.9, 0.0, 1.0);
		VERTEX.x += sin(TIME * 3.1 + VERTEX.y * 7.0 + VERTEX.z * 5.0) * onda * k;
		VERTEX.z += cos(TIME * 2.7 + VERTEX.y * 6.0 + VERTEX.x * 5.0) * onda * k;
	}
}

void fragment() {
	vec3 n = normalize(NORMAL);
	if (!FRONT_FACING) n = -n;
	vec3 nw = normalize((INV_VIEW_MATRIX * vec4(n, 0.0)).xyz);
	vec4 base = cor;
	if (tem_tex) base *= texture(tex, UV * uv_escala + uv_desloc);
	float dk = dot(nw, normalize(luz_chave));
	float dc = dot(nw, normalize(luz_contra));
	vec3 amb = mix(chao, ceu, nw.y * 0.5 + 0.5) * forca_amb;
	vec3 luz = amb + cor_chave * degrau(dk) * forca_chave + cor_contra * step(0.35, dc) * forca_contra * 0.6;
	float aro = pow(1.0 - clamp(dot(n, normalize(-VERTEX)), 0.0, 1.0), 3.0);
	luz += cor_aro * step(0.4, aro) * forca_aro;
	if (forca_quente > 0.0) luz += cor_quente * degrau(dot(nw, normalize(luz_quente + vec3(0.0, 0.3, 0.2)))) * forca_quente;
	if (recorte && base.a < 0.5) discard;
	ALBEDO = mix(base.rgb * luz * brilho + emissao, vec3(1.0), flash);
}
