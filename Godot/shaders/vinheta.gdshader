// Moldura de cor por cima do cenário: cantos escuros arroxeados e um leve toque de cor.
shader_type canvas_item;
uniform float forca = 0.55;
void fragment() {
	vec2 p = (SCREEN_UV - 0.5) * vec2(1.6, 1.0);
	float v = smoothstep(0.45, 1.05, length(p));
	COLOR = vec4(0.05, 0.02, 0.1, v * forca);
}
