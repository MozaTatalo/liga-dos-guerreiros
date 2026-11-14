// Imagem fantasma do herói: a silhueta guardada, pintada de luz colorida e somada à cena.
shader_type canvas_item;
render_mode blend_add;
void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec3 corpo = t.rgb / max(t.a, 0.001);
	float claro = dot(corpo, vec3(0.3, 0.5, 0.2));
	COLOR = vec4(COLOR.rgb * (0.55 + claro * 0.9), t.a * COLOR.a);
}
