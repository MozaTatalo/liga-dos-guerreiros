// Sprite do herói (o boneco 3D renderizado numa janela transparente).
// - mistura pré-multiplicada: tira a franja escura da borda;
// - luz de contorno pela silhueta: a borda do lado da lua acende na cor da luz da fase;
// - cor chapada para piscar ao levar dano.
shader_type canvas_item;
render_mode blend_premul_alpha;
uniform vec2 dir_aro = vec2(0.55, -0.83);     // para onde fica a lua na tela
uniform vec4 cor_aro : source_color = vec4(0.74, 0.8, 1.0, 1.0);
uniform float forca_aro = 0.85;
uniform float larg = 4.5;                      // largura da borda acesa, em pontos da textura
uniform float lado = 1.0;                      // -1 com o sprite espelhado
uniform vec4 pisca : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float opac = 1.0;
void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec2 d = dir_aro * vec2(lado, 1.0) * TEXTURE_PIXEL_SIZE * larg;
	float fora = 1.0 - min(texture(TEXTURE, UV + d).a, texture(TEXTURE, UV + d * 0.5).a);
	float aro = smoothstep(0.3, 0.7, fora) * forca_aro;
	vec3 c = mix(t.rgb, cor_aro.rgb * t.a, aro);
	c = mix(c, pisca.rgb * t.a, pisca.a);
	COLOR = vec4(c, t.a) * opac;
}
