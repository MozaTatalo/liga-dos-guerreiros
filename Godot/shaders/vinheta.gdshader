// Tratamento de cor final, por cima do cenário e dos personagens e por baixo da interface:
// sombras puxadas para o frio, luzes para o quente, um pouco mais de contraste e cantos escurecidos.
shader_type canvas_item;
uniform sampler2D tela : hint_screen_texture, filter_linear;
uniform float forca = 0.55;
void fragment() {
	vec3 c = texture(tela, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c += vec3(-0.012, 0.0, 0.028) * (1.0 - smoothstep(0.0, 0.45, l));
	c += vec3(0.035, 0.014, -0.02) * smoothstep(0.55, 1.0, l);
	c = mix(c, c * c * (3.0 - 2.0 * c), 0.22);
	vec2 p = (SCREEN_UV - 0.5) * vec2(1.6, 1.0);
	float v = smoothstep(0.45, 1.05, length(p));
	COLOR = vec4(mix(c, vec3(0.05, 0.02, 0.1), v * forca), 1.0);
}
