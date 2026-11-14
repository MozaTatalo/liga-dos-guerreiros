// Cenário gótico: luz em degraus (lua fria por trás, luz de frente suave, céu e chão),
// luz quente dos braseiros que tremula e névoa azulada pela distância, como no gotico.html.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool tem_tex = false;
uniform vec4 cor : source_color = vec4(1.0);
uniform bool sem_luz = false;      // silhuetas distantes e vitrais
uniform float brilho_proprio = 1.0;
uniform float forca_nevoa = 1.0;
uniform vec3 nevoa : source_color = vec3(0.13, 0.12, 0.26);
uniform float nevoa_perto = 16.0;
uniform float nevoa_longe = 78.0;
uniform vec3 ceu : source_color = vec3(0.45, 0.46, 0.86);
uniform vec3 chao : source_color = vec3(0.12, 0.07, 0.16);
uniform vec3 cor_lua : source_color = vec3(0.62, 0.68, 1.0);
uniform vec3 cor_aro : source_color = vec3(0.6, 0.55, 1.0);
uniform float forca_aro = 0.55;
uniform vec3 dir_lua = vec3(-0.35, 0.75, -0.55);
uniform vec3 cor_frente : source_color = vec3(0.788, 0.761, 0.847);
uniform vec3 dir_frente = vec3(0.35, 0.45, 1.0);
uniform vec3 cor_brasa : source_color = vec3(1.0, 0.5, 0.18);
uniform vec3 brasas[24];
uniform int n_brasas = 0;
uniform float tom = 1.0;           // escurece a área do chefe
uniform float pedra = 0.0;         // 1 = pedra: manchas do tempo, juntas dos blocos e base escurecida
uniform float molhado = 0.0;       // 1 = chão úmido: reflete o fogo dos braseiros

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}

float degrau(float d) {
	float k = clamp(d * 0.5 + 0.5, 0.0, 0.999);
	return k < 0.25 ? 0.227 : (k < 0.5 ? 0.47 : (k < 0.75 ? 0.745 : 1.0));
}

void fragment() {
	vec4 base = cor;
	if (tem_tex) base *= texture(tex, UV);
	vec3 c;
	if (sem_luz) {
		c = base.rgb * brilho_proprio;
	} else {
		vec3 n = normalize(NORMAL);
		if (!FRONT_FACING) n = -n;
		vec3 nw = normalize((INV_VIEW_MATRIX * vec4(n, 0.0)).xyz);
		vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		vec3 olho = normalize(wp - CAMERA_POSITION_WORLD);
		vec3 espelho = vec3(olho.x, -olho.y, olho.z);
		vec3 reflexo = vec3(0.0);
		if (pedra > 0.0) {
			// pedra velha: manchas largas, escorridos na vertical e a base mais escura e esverdeada
			vec2 lado = vec2(wp.x + wp.z * 0.7, wp.y);
			float mancha = ruido(lado * 1.3) * 0.6 + ruido(lado * vec2(5.0, 1.6)) * 0.4;
			base.rgb *= 0.86 + 0.26 * mancha;
			float pe = 1.0 - smoothstep(0.0, 1.1, wp.y);
			base.rgb = mix(base.rgb, base.rgb * vec3(0.62, 0.74, 0.66), pe * 0.55 * abs(nw.y - 1.0));
			// juntas dos blocos (só nas partes altas: pilares, arcos e paredes)
			float fiada = wp.y / 0.46;
			float n_fiada = floor(fiada);
			float junta_h = abs(fract(fiada) - 0.5) * 0.46;
			float col = (wp.x + wp.z) / 0.82 + mod(n_fiada, 2.0) * 0.5;
			float junta_v = abs(fract(col) - 0.5) * 0.82;
			float junta = 1.0 - smoothstep(0.012, 0.03, min(0.23 - junta_h, 0.41 - junta_v));
			float alto = smoothstep(1.7, 2.5, wp.y) * (1.0 - smoothstep(0.6, 0.9, abs(nw.y)));
			base.rgb *= 1.0 - junta * 0.34 * alto;
			base.rgb *= 1.0 + (h21(vec2(n_fiada, floor(col))) - 0.5) * 0.16 * alto;
		}
		vec3 luz = mix(chao, ceu, nw.y * 0.5 + 0.5) * 0.55;
		luz += cor_lua * degrau(dot(nw, normalize(dir_lua))) * 0.75;
		luz += cor_frente * degrau(dot(nw, normalize(dir_frente))) * 0.42;
		for (int i = 0; i < n_brasas; i++) {
			vec3 lp = brasas[i] + vec3(0.0, 0.18, 0.6);
			vec3 dl = lp - wp;
			float d = length(dl);
			if (d < 10.0) {
				float tremor = 0.85 + 0.15 * sin(TIME * 9.0 + float(i) * 1.7) * sin(TIME * 5.3 + float(i));
				float at = pow(1.0 - d / 10.0, 1.6) * tremor;
				luz += cor_brasa * 1.9 * at * clamp(dot(nw, dl / d) * 0.7 + 0.3, 0.0, 1.0);
			}
			if (molhado > 0.0 && d < 16.0) {
				// reflexo do fogo no chão úmido: um risco de luz esticado na direção de quem olha
				vec3 chama = brasas[i] + vec3(0.0, 0.1, 0.0);
				float tr = dot(chama - wp, espelho);
				vec3 falta = chama - (wp + espelho * max(tr, 0.0));
				float dr = length(vec3(falta.x, falta.y * 0.28, falta.z));
				float tremor2 = 0.8 + 0.2 * sin(TIME * 9.0 + float(i) * 1.7);
				reflexo += cor_brasa * smoothstep(0.42, 0.0, dr) * tremor2 * (1.0 - d / 16.0);
			}
		}
		// contorno de luz da lua nas bordas (o "brilho de anime" nas silhuetas)
		float aro = pow(1.0 - clamp(dot(n, normalize(-VERTEX)), 0.0, 1.0), 3.0);
		luz += cor_aro * step(0.35, aro) * forca_aro * clamp(nw.y * 0.5 + 0.6, 0.0, 1.0);
		c = base.rgb * luz * tom + reflexo * molhado * (0.35 + 0.65 * dot(base.rgb, vec3(0.5))) * tom;
	}
	float f = clamp((-VERTEX.z - nevoa_perto) / (nevoa_longe - nevoa_perto), 0.0, 1.0) * forca_nevoa;
	ALBEDO = mix(c, nevoa, f);
}
