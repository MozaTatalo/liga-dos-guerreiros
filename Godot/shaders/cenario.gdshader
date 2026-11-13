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
uniform vec3 nevoa : source_color = vec3(0.106, 0.129, 0.212);
uniform float nevoa_perto = 16.0;
uniform float nevoa_longe = 78.0;
uniform vec3 ceu : source_color = vec3(0.435, 0.498, 0.722);
uniform vec3 chao : source_color = vec3(0.082, 0.071, 0.11);
uniform vec3 cor_lua : source_color = vec3(0.663, 0.737, 1.0);
uniform vec3 dir_lua = vec3(-0.35, 0.75, -0.55);
uniform vec3 cor_frente : source_color = vec3(0.788, 0.761, 0.847);
uniform vec3 dir_frente = vec3(0.35, 0.45, 1.0);
uniform vec3 cor_brasa : source_color = vec3(1.0, 0.541, 0.235);
uniform vec3 brasas[24];
uniform int n_brasas = 0;
uniform float tom = 1.0;           // escurece a área do chefe

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
				luz += cor_brasa * 1.5 * at * clamp(dot(nw, dl / d) * 0.7 + 0.3, 0.0, 1.0);
			}
		}
		c = base.rgb * luz * tom;
	}
	float f = clamp((-VERTEX.z - nevoa_perto) / (nevoa_longe - nevoa_perto), 0.0, 1.0) * forca_nevoa;
	ALBEDO = mix(c, nevoa, f);
}
