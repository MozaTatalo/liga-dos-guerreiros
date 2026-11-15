// Sombreamento anime: três tons com a sombra TINGIDA (puxada para o violeta) em vez de escurecida,
// faixa de transição nítida e sem serrilhado, luz de contorno, luz quente do braseiro e brilho do cabelo.
// Ver cofre: Arte/Pesquisa - Arte e Animação.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool tem_tex = false;
uniform vec4 cor : source_color = vec4(1.0);
uniform vec2 uv_escala = vec2(1.0);
uniform vec2 uv_desloc = vec2(0.0);
uniform vec3 tinta_sombra : source_color = vec3(0.56, 0.54, 0.84);   // multiplica a cor na sombra
uniform float limiar = 0.02;       // onde a sombra começa
uniform float rosto = 0.0;         // 1 = quase sem sombra (rosto pintado à mão)
uniform float anel = 0.0;          // brilho em faixa no cabelo ("anel de anjo")
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

varying vec3 pos_obj;

void vertex() {
	pos_obj = VERTEX;
	if (onda > 0.0) {
		float k = clamp(1.0 - (VERTEX.y + 0.05) / 0.9, 0.0, 1.0);
		VERTEX.x += sin(TIME * 3.1 + VERTEX.y * 7.0 + VERTEX.z * 5.0) * onda * k;
		VERTEX.z += cos(TIME * 2.7 + VERTEX.y * 6.0 + VERTEX.x * 5.0) * onda * k;
	}
}

float faixa(float lim, float d, float w) {
	return smoothstep(lim - w, lim + w, d);
}

void fragment() {
	vec3 n = normalize(NORMAL);
	if (!FRONT_FACING) n = -n;
	vec3 nw = normalize((INV_VIEW_MATRIX * vec4(n, 0.0)).xyz);
	vec4 base = cor;
	if (tem_tex) base *= texture(tex, UV * uv_escala + uv_desloc);
	if (recorte && base.a < 0.5) discard;
	float dk = dot(nw, normalize(luz_chave));
	float w = fwidth(dk) * 1.2 + 0.006;
	float claro = mix(faixa(limiar, dk, w), 1.0, rosto * 0.85);
	float fundo = mix(faixa(-0.58, dk, w), 1.0, rosto);
	float alto = faixa(0.86, dk, w) * (1.0 - rosto);
	// sombra tingida: a cor base multiplicada pela tinta; a sombra funda leva a tinta duas vezes
	vec3 s1 = base.rgb * tinta_sombra;
	vec3 s2 = s1 * mix(vec3(1.0), tinta_sombra, 0.75);
	vec3 c = mix(mix(s2, s1, fundo), base.rgb, claro);
	c *= mix(vec3(1.0), cor_chave, 0.65) * (0.44 + forca_chave * 0.72);
	c += base.rgb * alto * 0.10;
	// luz ambiente bem leve do céu (em cima) e do chão (embaixo)
	c += base.rgb * mix(chao, ceu, nw.y * 0.5 + 0.5) * forca_amb * 0.22;
	// contraluz fria por trás
	float dc = dot(nw, normalize(luz_contra));
	c += base.rgb * cor_contra * faixa(0.35, dc, w) * forca_contra * 0.3;
	// luz de contorno nas bordas viradas para cima e para trás
	float borda = 1.0 - clamp(dot(n, normalize(-VERTEX)), 0.0, 1.0);
	float aro = faixa(0.62, borda, fwidth(borda) + 0.01) * clamp(nw.y * 0.7 + 0.55, 0.0, 1.0);
	c += cor_aro * aro * forca_aro * 0.8;
	// luz quente do braseiro mais perto
	if (forca_quente > 0.0) {
		float dq = dot(nw, normalize(luz_quente + vec3(0.0, 0.3, 0.2)));
		c += base.rgb * cor_quente * (faixa(0.1, dq, w) * 0.7 + faixa(0.7, dq, w) * 0.5) * forca_quente;
	}
	// brilho do cabelo: uma faixa em zigue-zague a uma altura fixa da cabeça, só no lado iluminado
	if (anel > 0.0) {
		float ang = atan(pos_obj.z, pos_obj.x);
		float zig = abs(fract(ang * 5.0) - 0.5) * 0.16;
		float h = pos_obj.y - 0.48 - zig;
		float b = smoothstep(0.0, 0.02, h) * (1.0 - smoothstep(0.1, 0.12, h));
		c += vec3(1.0, 0.97, 0.94) * b * claro * anel * 0.28;
	}
	ALBEDO = mix(c * brilho + emissao, vec3(1.0), flash);
}
