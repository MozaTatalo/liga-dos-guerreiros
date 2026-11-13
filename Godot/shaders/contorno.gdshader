// Contorno por casca invertida, como o contorno() do kael.js.
shader_type spatial;
render_mode unshaded, cull_front;
uniform float esp = 0.01;
// no jogo o boneco aparece pequeno: engrossa o contorno para continuar legível
uniform float escala = 2.0;
uniform vec3 cor : source_color = vec3(0.024, 0.02, 0.04);
void vertex() { VERTEX += normalize(NORMAL) * esp * escala; }
void fragment() { ALBEDO = cor; }
