// Brilho aditivo virado para a câmera (chamas, halos, olhos dos espectros, cinzas).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
uniform vec4 cor : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform float forca = 1.0;
uniform float tremor = 0.0;
uniform float fase = 0.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0, 0, 0), vec4(0, length(MODEL_MATRIX[1].xyz), 0, 0), vec4(0, 0, 1, 0), vec4(0, 0, 0, 1));
}
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float a = clamp(1.0 - r, 0.0, 1.0);
	a = a * a * (0.45 + 0.55 * smoothstep(0.75, 0.0, r));
	float t = 1.0 + tremor * (0.2 * sin(TIME * 11.0 + fase) + 0.12 * sin(TIME * 23.0 + fase * 2.0));
	ALBEDO = cor.rgb * a * forca * cor.a * t;
}
