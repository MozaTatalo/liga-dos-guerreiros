// Faixa de névoa rasteira, mistura normal e bem transparente.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
uniform vec4 cor : source_color = vec4(0.52, 0.58, 0.77, 0.1);
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0, 0, 0), vec4(0, length(MODEL_MATRIX[1].xyz), 0, 0), vec4(0, 0, 1, 0), vec4(0, 0, 0, 1));
}
void fragment() {
	vec2 d = (UV - 0.5) * 2.0;
	float a = clamp(1.0 - length(d), 0.0, 1.0);
	ALBEDO = cor.rgb; ALPHA = a * a * cor.a;
}
