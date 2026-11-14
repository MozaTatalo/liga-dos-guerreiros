// Sombra redonda e macia no chão, embaixo de heróis e inimigos.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
uniform float forca = 0.55;
void fragment() {
	float r = length((UV - 0.5) * 2.0);
	ALBEDO = vec3(0.04, 0.02, 0.08);
	ALPHA = smoothstep(1.0, 0.2, r) * forca;
}
