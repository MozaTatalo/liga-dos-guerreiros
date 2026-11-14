// Vitral gótico desenhado em código: duas lancetas com losangos de vidro, medalhões, rosácea no alto,
// barras de ferro e filetes de chumbo. Cada janela puxa a paleta para um lado (azul-violeta ou carmesim-âmbar).
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float larg = 1.3;
uniform float alt = 5.695;
uniform float brilho = 1.0;
uniform vec3 nevoa : source_color = vec3(0.13, 0.12, 0.26);
uniform float nevoa_perto = 16.0;
uniform float nevoa_longe = 78.0;
uniform float forca_nevoa = 0.5;
uniform float tom = 1.0;
varying vec3 wp;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

vec3 vidro(float h, float quente) {
	vec3 azul = vec3(0.07, 0.18, 0.70), violeta = vec3(0.40, 0.14, 0.68), carmim = vec3(0.74, 0.08, 0.20);
	vec3 ambar = vec3(0.95, 0.56, 0.12), verde = vec3(0.05, 0.46, 0.50), claro = vec3(0.78, 0.83, 0.96);
	vec3 a = h < 0.36 ? azul : (h < 0.60 ? violeta : (h < 0.76 ? verde : (h < 0.93 ? azul * 1.25 : claro)));
	vec3 b = h < 0.34 ? carmim : (h < 0.58 ? violeta : (h < 0.80 ? ambar : (h < 0.93 ? carmim * 1.2 : claro)));
	return mix(a, b, quente);
}

void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	float x = (UV.x - 0.5) * larg;
	float y = (1.0 - UV.y) * alt;
	float quente = smoothstep(-0.3, 0.3, sin(wp.x * 0.6 + 1.0));
	float chumbo = 0.0;
	vec3 c;
	// losangos de vidro
	vec2 q = vec2(x, y) / 0.17;
	vec2 d = vec2(q.x + q.y * 0.62, q.x - q.y * 0.62);
	vec2 cel = floor(d), f = fract(d);
	float borda = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	chumbo = max(chumbo, 1.0 - smoothstep(0.035, 0.075, borda));
	float h = h21(cel + floor(wp.x * 0.39) * 7.0);
	c = vidro(h, quente) * (0.62 + 0.38 * smoothstep(0.0, 0.45, borda));
	// faixa de borda em volta de cada lanceta
	float lx = abs(abs(x) - larg * 0.25);            // distância ao eixo da lanceta
	float margem = larg * 0.25 - lx;                 // distância à lateral da lanceta
	if (margem < 0.075) {
		float seg = fract(y / 0.22);
		c = mix(vidro(0.05, 1.0 - quente), vec3(0.95, 0.70, 0.22), step(0.5, seg) * 0.85) * 0.9;
		chumbo = max(chumbo, 1.0 - smoothstep(0.012, 0.03, abs(margem - 0.075)));
		chumbo = max(chumbo, 1.0 - smoothstep(0.01, 0.028, min(seg, abs(seg - 0.5)) * 0.22));
	}
	// medalhões: um em cada lanceta, alternando a altura
	for (int i = 0; i < 3; i++) {
		float my = 1.05 + float(i) * 1.42 + (x > 0.0 ? 0.3 : 0.0);
		vec2 m = vec2(lx, y - my);
		float r = length(m);
		if (r < 0.2) {
			float ang = atan(m.y, abs(x) - larg * 0.25);
			float petala = abs(fract(ang / 6.2832 * 4.0 + 0.125) - 0.5);
			c = r < 0.075 ? vec3(0.98, 0.78, 0.30) : mix(vidro(0.1, 1.0 - quente) * 1.2, vidro(0.5, quente), step(0.25, petala));
			chumbo = max(chumbo, 1.0 - smoothstep(0.008, 0.024, abs(r - 0.075)));
			chumbo = max(chumbo, (1.0 - smoothstep(0.02, 0.06, abs(petala - 0.25))) * step(0.075, r));
		}
		chumbo = max(chumbo, 1.0 - smoothstep(0.012, 0.03, abs(r - 0.2)));
	}
	// rosácea no alto
	vec2 pr = vec2(x, y - (alt - 0.82));
	float rr = length(pr);
	if (rr < 0.46) {
		float ang = atan(pr.y, pr.x);
		float pet = fract(ang / 6.2832 * 8.0);
		float lobo = 0.30 + 0.11 * cos((pet - 0.5) * 6.2832);
		if (rr < 0.1) c = vec3(1.0, 0.82, 0.34);
		else if (rr < lobo) c = vidro(floor(ang / 6.2832 * 8.0 + 8.0) * 0.123 + 0.02, 1.0 - quente) * 1.15;
		else c = vidro(0.3, quente) * 0.8;
		chumbo = max(chumbo, 1.0 - smoothstep(0.01, 0.028, abs(rr - 0.1)));
		chumbo = max(chumbo, (1.0 - smoothstep(0.01, 0.03, abs(rr - lobo))) );
		chumbo = max(chumbo, (1.0 - smoothstep(0.03, 0.08, min(pet, 1.0 - pet))) * step(0.1, rr) * step(rr, lobo));
	}
	chumbo = max(chumbo, 1.0 - smoothstep(0.012, 0.032, abs(rr - 0.46)));
	// pilarzinho central e barras de ferro
	chumbo = max(chumbo, (1.0 - smoothstep(0.02, 0.04, abs(x))) * step(y, alt - 1.28));
	chumbo = max(chumbo, 1.0 - smoothstep(0.012, 0.03, abs(fract(y / 0.95 + 0.4) - 0.5) * 0.95));
	// o vidro não é liso: manchas e um brilho lento, como luar atravessando
	float mancha = 0.82 + 0.3 * h21(floor(vec2(x, y) * 26.0));
	float luar = 0.85 + 0.15 * sin(TIME * 0.5 + wp.x * 0.7 + y * 0.9);
	c *= mancha * luar * brilho * (0.72 + 0.28 * smoothstep(0.0, alt, y));
	c = mix(c, vec3(0.012, 0.012, 0.03), chumbo);
	float fg = clamp((-VERTEX.z - nevoa_perto) / (nevoa_longe - nevoa_perto), 0.0, 1.0) * forca_nevoa;
	ALBEDO = mix(c * tom, nevoa, fg);
}
