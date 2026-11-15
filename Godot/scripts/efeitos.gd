class_name Efeitos
extends RefCounted
## Efeitos de ataques e poderes. Três camadas, todas no fx_layer:
##   "luz"     soma de luz com cor chapada e brilhos macios (clarões, raios, runas, faíscas)
##   "energia" soma de luz com o shader energia.gdshader (cortes, ondas, pilares, fogo: borda que se desfaz)
##   "normal"  desenho comum (fumaça, lascas de pedra)
## Aqui só há imagem: nenhum efeito muda dano, alcance ou tempo de golpe.

static var _brilho: Texture2D
static var _ruido: Texture2D

## Brilho macio redondo (branco no centro, some na borda).
static func tex_brilho() -> Texture2D:
	if _brilho == null:
		var gr := Gradient.new()
		gr.offsets = PackedFloat32Array([0.0, 0.18, 0.45, 0.75, 1.0])
		gr.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.62), Color(1, 1, 1, 0.2), Color(1, 1, 1, 0.045), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = gr
		t.width = 64; t.height = 64
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5); t.fill_to = Vector2(1.0, 0.5)
		_brilho = t
	return _brilho

## Ruído que repete sem emenda, usado pelo shader de energia.
static func tex_ruido() -> Texture2D:
	if _ruido == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.frequency = 0.035
		n.fractal_type = FastNoiseLite.FRACTAL_FBM
		n.fractal_octaves = 3
		n.seed = 7
		_ruido = ImageTexture.create_from_image(n.get_seamless_image(128, 128, false, false, 0.25, true))
	return _ruido

# ---------------------------------------------------------------- registro
## Registra um efeito: `fn(cv, k)` desenha na camada escolhida, com k indo de 0 a 1 em `vida` passos.
static func fx(g, vida: int, fn: Callable, camada := "luz") -> void:
	g.fx.append({"t": 0, "life": vida, "draw": fn, "camada": camada, "normal": camada == "normal"})

## Efeito preso a uma habilidade: anda no relógio dela (para junto com a pausa de impacto) e some se ela for interrompida.
## `fn(cv, k)` recebe k de 0 a 1 ao longo dos primeiros `dur` passos da habilidade `i` do herói `h`.
static func fx_hab(h, i: int, dur: int, fn: Callable, camada := "luz") -> void:
	var fim := [false]
	h.game.fx.append({"t": 0, "life": dur * 3 + 90, "camada": camada, "normal": camada == "normal", "draw": func(cv: CanvasItem, _k: float):
		if fim[0]:
			return
		if not is_instance_valid(h) or h.state != "skill" or h.skill != i or h.state_t > dur:
			fim[0] = true
			return
		fn.call(cv, float(h.state_t) / dur)})

## Arredonda k em degraus (efeito desenhado à mão: segura cada desenho por um instante).
static func deg(k: float, n := 6.0) -> float:
	return floorf(k * n) / n

static func sai(k: float, p := 3.0) -> float:
	return 1.0 - pow(1.0 - k, p)

# ---------------------------------------------------------------- peças de desenho
static func brilho(cv: CanvasItem, p: Vector2, r: float, cor, a := 1.0, esc := Vector2.ONE, rot := 0.0) -> void:
	if a <= 0.003 or r <= 0.0:
		return
	var c := Gfx.col(cor, a)
	cv.draw_set_transform(p, rot, esc)
	cv.draw_texture_rect(tex_brilho(), Rect2(-r, -r, r * 2.0, r * 2.0), false, c)
	cv.draw_set_transform_matrix(Transform2D.IDENTITY)

## Estrela de luz de quatro pontas (reflexo), com miolo redondo.
static func estrela(cv: CanvasItem, p: Vector2, r: float, cor, a := 1.0, rot := 0.0) -> void:
	brilho(cv, p, r, cor, a, Vector2(1.0, 0.11), rot)
	brilho(cv, p, r * 0.8, cor, a, Vector2(0.11, 1.0), rot)
	brilho(cv, p, r * 0.34, Color.WHITE, a)

static func _malha(cv: CanvasItem, vs: PackedVector2Array, cs: PackedColorArray, uvs: PackedVector2Array, tiras: int) -> void:
	# `tiras` pares de vértices seguidos (borda de fora, borda de dentro) viram uma fita
	var idx := PackedInt32Array()
	for i in tiras - 1:
		var o := i * 2
		idx.append_array(PackedInt32Array([o, o + 1, o + 3, o, o + 3, o + 2]))
	RenderingServer.canvas_item_add_triangle_array(cv.get_canvas_item(), idx, vs, cs, uvs)

## Meia-lua de energia (camada "energia"): arco de a0 a a1, grossa no meio e fina nas pontas.
## Ângulos em radianos com o herói olhando para a direita: 0 = frente, -PI/2 = cima, PI/2 = baixo. `esc.x = -1` espelha.
static func meia_lua(cv: CanvasItem, c: Vector2, raio: float, a0: float, a1: float, larg: float, cor, vida: float, esc := Vector2.ONE, afina := true, n := 18) -> void:
	if vida <= 0.01:
		return
	var col := Gfx.col(cor); col.a = clampf(vida, 0.0, 1.0)
	var vs := PackedVector2Array(); var cs := PackedColorArray(); var uvs := PackedVector2Array()
	var vs2 := PackedVector2Array(); var uvs2 := PackedVector2Array()
	var comp := maxf(absf(a1 - a0) * raio / 46.0, 0.6)
	for i in n + 1:
		var u := float(i) / n
		var a := lerpf(a0, a1, u)
		var d := Vector2(cos(a), sin(a))
		var g := larg * (pow(sin(PI * u), 0.55) if afina else 1.0)
		vs.append(c + d * (raio + g * 0.12) * esc); vs.append(c + d * (raio - g * 0.16) * esc)
		uvs.append(Vector2(u * comp, 0.08)); uvs.append(Vector2(u * comp, 0.5))
		cs.append(col); cs.append(col)
		vs2.append(c + d * (raio - g * 0.16) * esc); vs2.append(c + d * (raio - g * 0.88) * esc)
		uvs2.append(Vector2(u * comp, 0.5)); uvs2.append(Vector2(u * comp, 1.0))
	_malha(cv, vs, cs, uvs, n + 1)
	_malha(cv, vs2, cs, uvs2, n + 1)

## Anel de energia inteiro (onda de choque). `esc.y` pequeno deita o anel no chão.
static func anel(cv: CanvasItem, c: Vector2, raio: float, larg: float, cor, vida: float, esc := Vector2.ONE) -> void:
	if vida <= 0.01:
		return
	var col := Gfx.col(cor); col.a = clampf(vida, 0.0, 1.0)
	var vs := PackedVector2Array(); var cs := PackedColorArray(); var uvs := PackedVector2Array()
	var n := 28
	var comp := maxf(roundf(TAU * raio / 46.0), 2.0)
	for i in n + 1:
		var u := float(i) / n
		var d := Vector2(cos(u * TAU), sin(u * TAU))
		vs.append(c + d * (raio + larg * 0.5) * esc); vs.append(c + d * (raio - larg * 0.5) * esc)
		uvs.append(Vector2(u * comp, 0.0)); uvs.append(Vector2(u * comp, 1.0))
		cs.append(col); cs.append(col)
	_malha(cv, vs, cs, uvs, n + 1)

## Feixe de energia de p0 a p1 com larguras l0 e l1 (pilares, estocadas, caudas).
static func feixe(cv: CanvasItem, p0: Vector2, p1: Vector2, l0: float, l1: float, cor, vida: float, v0 := -1.0) -> void:
	if vida <= 0.01:
		return
	var col := Gfx.col(cor); col.a = clampf(vida, 0.0, 1.0)
	var col0 := col
	if v0 >= 0.0: col0.a = clampf(v0, 0.0, 1.0)
	var d := p1 - p0
	var comp := d.length()
	if comp < 0.5:
		return
	var nrm := Vector2(-d.y, d.x) / comp
	var vs := PackedVector2Array(); var cs := PackedColorArray(); var uvs := PackedVector2Array()
	var n := 4
	for i in n + 1:
		var u := float(i) / n
		var p := p0.lerp(p1, u)
		var l := lerpf(l0, l1, u) * 0.5
		vs.append(p + nrm * l); vs.append(p - nrm * l)
		uvs.append(Vector2(u * comp / 46.0, 0.0)); uvs.append(Vector2(u * comp / 46.0, 1.0))
		var cc := col0.lerp(col, u)
		cs.append(cc); cs.append(cc)
	_malha(cv, vs, cs, uvs, n + 1)

## Bola de energia (fogo, explosão): disco com o miolo quente e a borda roída pelo ruído.
static func bola(cv: CanvasItem, c: Vector2, raio: float, cor, vida: float, esc := Vector2.ONE) -> void:
	if vida <= 0.01 or raio <= 0.2:
		return
	var col := Gfx.col(cor); col.a = clampf(vida, 0.0, 1.0)
	var vs := PackedVector2Array(); var cs := PackedColorArray(); var uvs := PackedVector2Array()
	var n := 20
	var comp := maxf(roundf(TAU * raio / 60.0), 2.0)
	for i in n + 1:
		var u := float(i) / n
		var d := Vector2(cos(u * TAU), sin(u * TAU))
		vs.append(c + d * raio * esc); vs.append(c)
		uvs.append(Vector2(u * comp, 1.0)); uvs.append(Vector2(u * comp, 0.5))
		cs.append(col); cs.append(col)
	_malha(cv, vs, cs, uvs, n + 1)

## Fita de luz que segue uma lista de pontos (o primeiro é o mais novo) e afina até sumir.
static func fita(cv: CanvasItem, pts: Array, larg: float, cor, a := 1.0) -> void:
	var n := pts.size()
	if n < 2:
		return
	var c := Gfx.col(cor)
	var vs := PackedVector2Array(); var cs := PackedColorArray()
	for i in n:
		var u := float(i) / (n - 1)
		var p: Vector2 = pts[i]
		var q: Vector2 = pts[mini(i + 1, n - 1)] if i < n - 1 else pts[i - 1]
		var d := (q - p) if i < n - 1 else (p - q)
		var nrm := Vector2(-d.y, d.x).normalized() * larg * 0.5 * (1.0 - u)
		vs.append(p + nrm); vs.append(p - nrm)
		var cc := Color(lerpf(1.0, c.r, minf(1.0, u * 3.0)), lerpf(1.0, c.g, minf(1.0, u * 3.0)), lerpf(1.0, c.b, minf(1.0, u * 3.0)), a * (1.0 - u))
		cs.append(cc); cs.append(cc)
	_malha(cv, vs, cs, PackedVector2Array(), n)

## Caminho de raio em ziguezague entre dois pontos; a mesma semente dá o mesmo desenho.
static func caminho_raio(p0: Vector2, p1: Vector2, semente: int, desvio := 0.2, niveis := 4) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var pts: Array = [p0, p1]
	var amp := (p1 - p0).length() * desvio
	for _n in niveis:
		var novo: Array = []
		for i in pts.size() - 1:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var d := b - a
			var m := (a + b) * 0.5 + Vector2(-d.y, d.x).normalized() * rng.randf_range(-amp, amp)
			novo.append(a); novo.append(m)
		novo.append(pts[pts.size() - 1])
		pts = novo
		amp *= 0.52
	return PackedVector2Array(pts)

## Desenha um raio: halo colorido, corpo e miolo branco.
static func raio(cv: CanvasItem, pts: PackedVector2Array, cor, a := 1.0, larg := 1.6) -> void:
	if pts.size() < 2:
		return
	cv.draw_polyline(pts, Gfx.col(cor, a * 0.28), larg * 3.6)
	cv.draw_polyline(pts, Gfx.col(cor, a * 0.85), larg * 1.5)
	cv.draw_polyline(pts, Color(1, 1, 1, a), larg * 0.6)

## Círculo de runas (magia do Oren): dois aros, marcas entre eles e uma estrela no meio. `esc` deita o círculo no chão (y pequeno) ou o vira de lado (x pequeno).
static func runas(cv: CanvasItem, c: Vector2, r: float, cor, a := 1.0, rot := 0.0, esc := Vector2(1.0, 0.32), pontas := 6) -> void:
	if a <= 0.01:
		return
	var col := Gfx.col(cor, a)
	var fraca := Gfx.col(cor, a * 0.55)
	cv.draw_set_transform(c, 0.0, esc)
	cv.draw_arc(Vector2.ZERO, r, 0, TAU, 44, col, 1.3)
	cv.draw_arc(Vector2.ZERO, r * 0.8, 0, TAU, 40, fraca, 0.9)
	cv.draw_arc(Vector2.ZERO, r * 0.4, 0, TAU, 24, fraca, 0.8)
	for i in 24:
		var ang := rot + i * TAU / 24.0
		var d := Vector2(cos(ang), sin(ang))
		if i % 3 == 0:
			var e := Vector2(cos(ang + 0.09), sin(ang + 0.09))
			cv.draw_line(d * r * 0.84, e * r * 0.96, col, 0.9)
			cv.draw_line(e * r * 0.96, Vector2(cos(ang + 0.18), sin(ang + 0.18)) * r * 0.84, col, 0.9)
		else:
			cv.draw_line(d * r * 0.86, d * r * (0.94 if i % 3 == 1 else 0.9), fraca, 0.8)
	var est := PackedVector2Array()
	var salto := 2 if pontas % 2 == 0 else (pontas / 2)
	for volta in (2 if pontas % 2 == 0 else 1):
		est.clear()
		for i in pontas / (2 if pontas % 2 == 0 else 1) + 1:
			var ang := -rot * 0.7 + (i * salto + volta) * TAU / pontas
			est.append(Vector2(cos(ang), sin(ang)) * r * 0.8)
		cv.draw_polyline(est, col, 1.0)
	cv.draw_set_transform_matrix(Transform2D.IDENTITY)

## Rosácea (o emblema da Ordem do Kael): aro, oito pétalas e raios, como um vitral de luz.
static func rosacea(cv: CanvasItem, c: Vector2, r: float, cor, a := 1.0, rot := 0.0, achat := 1.0) -> void:
	if a <= 0.01:
		return
	var col := Gfx.col(cor, a)
	var fraca := Gfx.col(cor, a * 0.5)
	cv.draw_set_transform(c, 0.0, Vector2(1.0, achat))
	cv.draw_arc(Vector2.ZERO, r, 0, TAU, 44, col, 1.6)
	cv.draw_arc(Vector2.ZERO, r * 0.9, 0, TAU, 40, fraca, 0.8)
	cv.draw_arc(Vector2.ZERO, r * 0.24, 0, TAU, 20, col, 1.2)
	for i in 8:
		var ang := rot + i * TAU / 8.0
		var d := Vector2(cos(ang), sin(ang))
		cv.draw_arc(d * r * 0.57, r * 0.3, 0, TAU, 20, col, 1.1)
		cv.draw_line(d * r * 0.24, d * r * 0.3, col, 1.0)
		var e := Vector2(cos(ang + TAU / 16.0), sin(ang + TAU / 16.0))
		cv.draw_line(e * r * 0.5, e * r * 0.9, fraca, 0.9)
	cv.draw_set_transform_matrix(Transform2D.IDENTITY)

# ---------------------------------------------------------------- partículas
## Brasas: pontos de luz que sobem, piscam e somem.
static func brasas(g, p: Vector2, n: int, cor, forca := 2.0, espalha := 4.0) -> void:
	for i in n:
		var a := randf_range(0, TAU)
		var s := randf_range(0.2, forca)
		var vida := randf_range(24, 52)
		g.parts.append({"x": p.x + randf_range(-espalha, espalha), "y": p.y + randf_range(-espalha, espalha), "vx": cos(a) * s, "vy": sin(a) * s - forca * 0.45,
			"life": vida, "vida": vida, "c": cor, "s": randf_range(0.7, 1.5), "g": -0.014, "d": 0.93, "tipo": "brasa", "f": randf() * 10.0})

## Línguas de fogo: nascem brancas, passam por amarelo e laranja e morrem vermelhas, subindo.
static func chamas(g, p: Vector2, n: int, raio := 5.0, forca := 1.0, espalha := 3.0) -> void:
	for i in n:
		var vida := randf_range(10, 18)
		g.parts.append({"x": p.x + randf_range(-espalha, espalha), "y": p.y + randf_range(-espalha, espalha), "vx": randf_range(-0.5, 0.5) * forca, "vy": randf_range(-1.1, -0.2) * forca,
			"life": vida, "vida": vida, "c": "#ff8a3d", "s": raio * randf_range(0.7, 1.2), "g": -0.02, "d": 0.94, "tipo": "chama"})

## Fumaça escura que cresce e sobe devagar (camada normal).
static func fumaca(g, p: Vector2, n: int, raio := 5.0, espalha := 6.0) -> void:
	for i in n:
		var vida := randf_range(28, 48)
		g.parts.append({"x": p.x + randf_range(-espalha, espalha), "y": p.y + randf_range(-espalha, espalha), "vx": randf_range(-0.5, 0.5), "vy": randf_range(-0.9, -0.3),
			"life": vida, "vida": vida, "c": "#241c38", "s": raio * randf_range(0.7, 1.3), "g": -0.008, "d": 0.95, "tipo": "fumaca"})

## Lascas de pedra que saltam e caem (camada normal).
static func lascas(g, p: Vector2, n: int, forca := 2.6) -> void:
	for i in n:
		var vida := randf_range(26, 44)
		g.parts.append({"x": p.x + randf_range(-5, 5), "y": p.y - 1.0, "vx": randf_range(-1.0, 1.0) * forca, "vy": randf_range(-1.6, -0.6) * forca,
			"life": vida, "vida": vida, "c": "#4a4470", "s": randf_range(0.9, 2.0), "g": 0.24, "tipo": "lasca", "f": randf() * 6.0})

## Centelhas mágicas: estrelinhas que cintilam e flutuam.
static func centelhas(g, p: Vector2, n: int, cor, espalha := 8.0, vel := 0.6) -> void:
	for i in n:
		var a := randf_range(0, TAU)
		var vida := randf_range(16, 34)
		g.parts.append({"x": p.x + randf_range(-espalha, espalha), "y": p.y + randf_range(-espalha, espalha), "vx": cos(a) * vel * randf(), "vy": sin(a) * vel * randf() - 0.15,
			"life": vida, "vida": vida, "c": cor, "s": randf_range(1.2, 2.4), "g": -0.004, "d": 0.96, "tipo": "centelha", "f": randf() * 10.0})

# ---------------------------------------------------------------- efeitos compostos
## Clarão macio que estoura e some.
static func clarao(g, p: Vector2, r: float, cor, vida := 8) -> void:
	fx(g, vida, func(cv: CanvasItem, k: float):
		var a := (1.0 - k) * (1.0 - k)
		brilho(cv, p, r * (0.7 + 0.5 * k), cor, a)
		brilho(cv, p, r * 0.42, Color.WHITE, a * 0.9))

## Reflexo em estrela que abre, gira um pouco e some.
static func reflexo(g, p: Vector2, r: float, cor, vida := 10, rot := 0.0) -> void:
	fx(g, vida, func(cv: CanvasItem, k: float):
		var abre := sai(minf(1.0, k * 3.0), 2.0)
		estrela(cv, p, r * abre * (1.0 - 0.4 * k), cor, 1.0 - k * k, rot + k * 0.6))

## Clarão na tela inteira (explosões grandes, supremas).
static func tela(g, cor, a := 0.2, vida := 6) -> void:
	fx(g, vida, func(cv: CanvasItem, k: float): cv.draw_rect(Rect2(g.cam_x - 60, -80, GameData.W + 120, GameData.H + 160), Gfx.col(cor, a * (1.0 - k))))

## Lâmina de energia: a meia-lua aparece varrendo de a0 a a1, avança um pouco e se desfaz.
static func lamina(g, p: Vector2, f: int, raio: float, a0: float, a1: float, cor, vida := 10, larg := -1.0, avanco := 5.0, esc := Vector2.ONE) -> void:
	var lg := larg if larg > 0.0 else raio * 0.5
	var e := Vector2(f, 1) * esc
	fx(g, vida, func(cv: CanvasItem, k: float):
		var varre := minf(1.0, k * vida / 2.5)
		var c := p + Vector2(f * avanco * sai(k, 2.0), 0)
		meia_lua(cv, c, raio * (1.0 + 0.1 * k), a0, lerpf(a0, a1, varre), lg * (1.0 - 0.35 * k), cor, 0.82 * (1.0 - pow(k, 1.3)), e), "energia")
	fx(g, maxi(3, vida / 3), func(cv: CanvasItem, k: float):
		cv.draw_set_transform(p + Vector2(f * avanco * k * 0.5, 0), 0.0, e)
		cv.draw_arc(Vector2.ZERO, raio * 1.02, lerpf(a0, a1, 0.15), lerpf(a0, a1, 0.85), 16, Color(1, 1, 1, 0.55 * (1.0 - k)), 0.8)
		cv.draw_set_transform_matrix(Transform2D.IDENTITY))

## Estocada: lança de energia para a frente, com anéis de vento atravessados e reflexo na ponta.
static func estocada(g, p: Vector2, dir: Vector2, comp: float, cor, larg := 9.0) -> void:
	var d := dir.normalized()
	var ang := d.angle()
	fx(g, 9, func(cv: CanvasItem, k: float):
		var av := sai(k, 2.5)
		feixe(cv, p + d * comp * 0.1 * av, p + d * comp * (0.65 + 0.35 * av), larg * (1.0 - 0.5 * k), 0.6, cor, 1.0 - pow(k, 1.5)), "energia")
	fx(g, 6, func(cv: CanvasItem, k: float):
		brilho(cv, p + d * comp * 0.5, comp * 0.62, Color.WHITE, 0.85 * (1.0 - k), Vector2(1.0, 0.05), ang)
		estrela(cv, p + d * comp, larg * 1.2 * (1.0 - k * 0.5), cor, 1.0 - k))
	for i in 2:
		var c := p + d * comp * (0.4 + 0.28 * i)
		var r0 := larg * (0.55 + 0.3 * i)
		fx(g, 9 + i * 2, func(cv: CanvasItem, k: float):
			cv.draw_set_transform(c + d * 6.0 * k, ang, Vector2(0.32, 1.0))
			cv.draw_arc(Vector2.ZERO, r0 * (0.5 + 1.2 * sai(k)), 0, TAU, 20, Gfx.col(cor, 0.9 * (1.0 - k)), 1.4 * (1.0 - k) + 0.3)
			cv.draw_set_transform_matrix(Transform2D.IDENTITY))

## Onda de choque no chão: anel deitado que abre, espigões de luz, poeira e lascas.
static func onda_chao(g, p: Vector2, raio: float, cor, forte := false) -> void:
	var vida := 16 if forte else 12
	fx(g, vida, func(cv: CanvasItem, k: float):
		var r := raio * (0.25 + 0.75 * sai(k, 2.5))
		anel(cv, p, r, raio * 0.34 * (1.0 - 0.5 * k), cor, 1.0 - pow(k, 1.4), Vector2(1.0, 0.3)), "energia")
	fx(g, 7, func(cv: CanvasItem, k: float): brilho(cv, p, raio, cor, 0.7 * (1.0 - k), Vector2(1.0, 0.32)))
	var n := 7 if forte else 5
	for i in n:
		var dx := (float(i) / (n - 1) - 0.5) * 2.0 * raio * 0.8 + randf_range(-3, 3)
		var alt := randf_range(10, 19) * (1.5 if forte else 1.0) * (1.0 - absf(dx) / (raio * 1.5))
		var atraso := absf(dx) / raio * 5.0
		var total := 9.0 + atraso
		fx(g, int(total), func(cv: CanvasItem, k: float):
			var kk := clampf((k * total - atraso) / 9.0, 0.0, 1.0)
			if kk > 0.0:
				feixe(cv, Vector2(p.x + dx, p.y), Vector2(p.x + dx * 1.08, p.y - alt * sai(kk, 2.0)), 5.0 * (1.0 - kk), 0.5, cor, 1.0 - kk * kk), "energia")
	g.dust(p.x, p.y, 8 if forte else 5)
	lascas(g, p, 7 if forte else 3, 3.0 if forte else 2.2)

## Coluna de energia que sobe do chão (pilares, golpes ascendentes).
static func coluna(g, px: float, base: float, alt: float, larg: float, cor, vida := 18) -> void:
	fx(g, vida, func(cv: CanvasItem, k: float):
		var sobe := minf(1.0, k * 4.5)
		var fecha := 1.0 - pow(k, 2.2)
		feixe(cv, Vector2(px, base), Vector2(px, base - alt * sobe), larg * fecha, larg * 0.75 * fecha, cor, 1.0 - pow(k, 1.8)), "energia")
	fx(g, vida, func(cv: CanvasItem, k: float):
		var sobe := minf(1.0, k * 4.5)
		var a := 1.0 - k
		var meia := alt * sobe * 0.55
		brilho(cv, Vector2(px, base - alt * sobe * 0.5), meia, Color.WHITE, 0.4 * a * a, Vector2(larg * 0.3 / maxf(meia, 1.0), 1.0))
		brilho(cv, Vector2(px, base), larg * 1.7, cor, 0.8 * a, Vector2(1.0, 0.3)))
	fx(g, 12, func(cv: CanvasItem, k: float): anel(cv, Vector2(px, base), larg * (0.6 + 1.7 * sai(k)), larg * 0.45 * (1.0 - k), cor, 1.0 - k, Vector2(1.0, 0.3)), "energia")

## Explosão em camadas: clarão branco, bola de fogo roída, onda de choque, brilho que fica, e partículas.
## `quente` = fogo (chamas, fumaça, brasas); frio = arcano (centelhas e reflexo).
static func explosao(g, p: Vector2, raio: float, cor_in, quente := true) -> void:
	# cor bem saturada: o branco fica só no miolo da energia
	var cor := Gfx.col(cor_in)
	cor.s = maxf(cor.s, 0.66)
	if quente: cor = cor.lerp(Color("#ff4a12"), 0.4)
	var claro := cor.lerp(Color(1.0, 0.95, 0.75) if quente else Color(0.9, 0.97, 1.0), 0.4)
	# quanto maior a explosão, menos luz por ponto: ela cresce em tamanho, não em branco
	var m := clampf(30.0 / raio, 0.4, 1.0)
	fx(g, 3, func(cv: CanvasItem, k: float): brilho(cv, p, raio * 0.7, Color.WHITE, 0.5 * m * (1.0 - k)))
	fx(g, 8, func(cv: CanvasItem, k: float):
		bola(cv, p, minf(raio, 30.0) * (0.3 + 0.5 * sai(k, 3.0)), cor, 0.8 * (1.0 - k)), "energia")
	var larg := minf(raio * 0.36, 15.0)
	fx(g, 16, func(cv: CanvasItem, k: float):
		anel(cv, p, raio * (0.28 + 0.7 * sai(k, 2.6)), larg * (1.0 - 0.7 * k), cor, 0.9 * (1.0 - pow(k, 1.4))), "energia")
	fx(g, 11, func(cv: CanvasItem, k: float):
		anel(cv, p, raio * (0.35 + 1.1 * sai(k, 2.5)), maxf(larg * 0.35, 3.0) * (1.0 - k), claro, 0.7 * (1.0 - k)), "energia")
	fx(g, 12, func(cv: CanvasItem, k: float): brilho(cv, p, raio * (1.0 + 0.5 * k), cor, 0.3 * m * (1.0 - k)))
	var n := clampi(int(raio / 7.0), 4, 16)
	if quente:
		chamas(g, p, n, raio * 0.22, 1.6, raio * 0.35)
		fumaca(g, p, n / 2, raio * 0.2, raio * 0.4)
		brasas(g, p, n, cor, 3.0, raio * 0.3)
	else:
		centelhas(g, p, n, claro, raio * 0.6, 1.6)
		reflexo(g, p, raio * 1.2, claro, 9)
	if raio >= 55.0:
		tela(g, cor, 0.08 if raio < 90.0 else 0.16, 6)

## Relâmpago vivo entre dois pontos: o desenho muda a cada dois passos, pisca e tem ramos.
static func relampago(g, p0: Vector2, p1: Vector2, cor, vida := 14, larg := 1.6, ramos := 2) -> void:
	var semente := randi() % 100000
	fx(g, vida, func(cv: CanvasItem, k: float):
		var passo := int(k * vida / 2.0)
		var a := 1.0 - k * k
		if passo % 3 == 2 and k < 0.8: a *= 0.45
		var pts := caminho_raio(p0, p1, semente + passo * 31, 0.16)
		raio(cv, pts, cor, a, larg)
		for r in ramos:
			var i := int(pts.size() * (0.3 + 0.3 * r))
			var fim := pts[i] + (p1 - p0).rotated(0.7 if (r + passo) % 2 == 0 else -0.7) * 0.22
			raio(cv, caminho_raio(pts[i], fim, semente + passo * 17 + r, 0.25, 3), cor, a * 0.6, larg * 0.6)
		brilho(cv, p1, 15.0, cor, a * 0.8); brilho(cv, p1, 6.0, Color.WHITE, a)
		brilho(cv, p0, 9.0, cor, a * 0.6))

## Círculo de runas que abre, gira e some. `esc` deita ou vira o círculo.
static func circulo_runas(g, p: Vector2, r: float, cor, vida := 30, esc := Vector2(1.0, 0.32), gira := 1.0, pontas := 6) -> void:
	fx(g, vida, func(cv: CanvasItem, k: float):
		var a := minf(1.0, k * 6.0) * minf(1.0, (1.0 - k) * 4.0)
		var rr := r * (0.55 + 0.45 * sai(minf(1.0, k * 4.0)))
		brilho(cv, p, rr * 1.2, cor, a * 0.35, esc)
		runas(cv, p, rr, cor, a, k * gira * 2.4, esc, pontas))

## Selo da Rosácea: o emblema acende, abre e some.
static func selo_rosacea(g, p: Vector2, r: float, cor, vida := 18, achat := 1.0) -> void:
	fx(g, vida, func(cv: CanvasItem, k: float):
		var a := minf(1.0, k * 6.0) * (1.0 - k * k)
		var rr := r * (0.5 + 0.5 * sai(minf(1.0, k * 3.0)))
		brilho(cv, p, rr * 1.5, cor, a * 0.4, Vector2(1.0, achat))
		rosacea(cv, p, rr, cor, a, k * 0.5, achat))

## Leque de raios de luz saindo de um ponto (despertar, morte do chefe, final de suprema).
static func raios_de_luz(g, p: Vector2, cor, n: int, comp: float, vida := 24) -> void:
	var rot0 := randf() * TAU
	fx(g, vida, func(cv: CanvasItem, k: float):
		var a := minf(1.0, k * 6.0) * (1.0 - k)
		var c0 := Gfx.col(cor, a * 0.75)
		var c1 := Gfx.col(cor, 0.0)
		for i in n:
			var ang := rot0 + i * TAU / n + sin(i * 12.9898) * 0.25 + k * 0.5
			var l := comp * (0.6 + 0.4 * fposmod(i * 0.618, 1.0)) * (0.5 + 0.5 * sai(k))
			var d := Vector2(cos(ang), sin(ang))
			var nr := Vector2(-d.y, d.x) * l * 0.075
			cv.draw_polygon(PackedVector2Array([p, p + d * l + nr, p + d * l - nr]), PackedColorArray([c0, c1, c1])))

## Acerto de golpe por tipo, por cima do impacto comum: "corte", "pancada", "flecha" ou "magia".
static func acerto(g, p: Vector2, dir: int, cor, forte := false, tipo := "") -> void:
	var tam := 11.0 if forte else 7.0
	fx(g, 5, func(cv: CanvasItem, k: float):
		brilho(cv, p, tam * 2.1, cor, 0.42 * (1.0 - k))
		brilho(cv, p, tam * 0.7, Color.WHITE, 0.75 * (1.0 - k)))
	match tipo:
		"corte":
			# risco de lâmina atravessando o alvo, mais uma lasca de energia cruzada
			var ang := (0.5 if randf() < 0.5 else -0.55) + randf_range(-0.2, 0.2)
			if dir < 0: ang = PI - ang
			var comp := tam * (3.8 if forte else 2.9)
			fx(g, 8, func(cv: CanvasItem, k: float):
				var kk := deg(k, 4.0)
				brilho(cv, p, comp * (0.7 + 0.5 * kk), Color.WHITE, 1.0 - k, Vector2(1.0, 0.06 * (1.0 - kk)), ang)
				brilho(cv, p, comp * (0.9 + 0.5 * kk), cor, 0.8 * (1.0 - k), Vector2(1.0, 0.15 * (1.0 - kk)), ang))
			var d := Vector2(cos(ang), sin(ang))
			fx(g, 9, func(cv: CanvasItem, k: float): feixe(cv, p - d * comp * 0.9, p + d * comp * (0.9 + 0.4 * k), tam * 0.9 * (1.0 - k), 0.4, cor, 1.0 - pow(k, 1.4), 0.0), "energia")
		"pancada":
			fx(g, 10, func(cv: CanvasItem, k: float): anel(cv, p, tam * (0.6 + 1.7 * sai(k)), tam * 0.36 * (1.0 - 0.5 * k), cor, 0.7 * (1.0 - k)), "energia")
			fx(g, 7, func(cv: CanvasItem, k: float): estrela(cv, p, tam * (2.2 + k), Color.WHITE, 1.0 - k, PI / 4.0))
		"flecha":
			var d2 := Vector2(dir, 0)
			fx(g, 7, func(cv: CanvasItem, k: float): brilho(cv, p + d2 * tam * k, tam * 3.0, Color.WHITE, 0.9 * (1.0 - k), Vector2(1.0, 0.07)))
			fx(g, 9, func(cv: CanvasItem, k: float):
				cv.draw_set_transform(p + d2 * 5.0 * k, 0.0, Vector2(0.34, 1.0))
				cv.draw_arc(Vector2.ZERO, tam * (0.6 + 1.6 * sai(k)), 0, TAU, 20, Gfx.col(cor, 1.0 - k), 1.6 * (1.0 - k) + 0.3)
				cv.draw_set_transform_matrix(Transform2D.IDENTITY))
		"magia":
			fx(g, 12, func(cv: CanvasItem, k: float): bola(cv, p, tam * (0.7 + 0.9 * sai(k)), cor, 0.8 * (1.0 - k)), "energia")
			centelhas(g, p, 5 if forte else 3, cor, tam, 1.4)
	if forte:
		reflexo(g, p, tam * 2.6, cor, 9, randf_range(-0.3, 0.3))
		if tipo != "pancada":
			fx(g, 10, func(cv: CanvasItem, k: float): anel(cv, p, tam * (0.9 + 1.9 * sai(k)), tam * 0.26 * (1.0 - 0.5 * k), cor, 0.6 * (1.0 - k)), "energia")

## Aviso de golpe de inimigo: um anel branco que se fecha sobre ele e um reflexo que estala (o sinal continua branco).
static func aviso(g, p: Vector2, r: float) -> void:
	fx(g, 12, func(cv: CanvasItem, k: float):
		var rr := r * (1.3 - 0.9 * sai(k, 2.0))
		var a := minf(1.0, k * 4.0) * (1.0 - k * 0.5)
		cv.draw_arc(p, rr, 0, TAU, 28, Color(1, 1, 1, 0.9 * a), 1.3)
		cv.draw_arc(p, rr * 1.25, 0, TAU, 28, Color(1, 1, 1, 0.3 * a), 0.8))
	reflexo(g, p + Vector2(0, -r * 0.2), r * 1.4, Color.WHITE, 12)

## Morte de inimigo: a energia dele estoura e sobe em brasas. O chefe se desfaz em coluna e raios de luz.
static func morte(g, p: Vector2, cor, chefe := false) -> void:
	var r := 46.0 if chefe else 15.0
	clarao(g, p, r * 1.7, cor, 10)
	fx(g, 14, func(cv: CanvasItem, k: float): anel(cv, p, r * (0.4 + 1.5 * sai(k)), r * 0.4 * (1.0 - k), cor, 1.0 - k), "energia")
	fx(g, 12, func(cv: CanvasItem, k: float): bola(cv, p, r * (0.5 + 0.6 * sai(k)), cor, 1.0 - pow(k, 0.8)), "energia")
	brasas(g, p, 26 if chefe else 8, cor, 2.4, r * 0.45)
	if chefe:
		raios_de_luz(g, p, cor, 12, 150.0, 46)
		coluna(g, p.x, GameData.GROUND, 170.0, 36.0, cor, 40)
		tela(g, "#ffffff", 0.35, 10)

# ================================================================ efeitos de cada golpe e habilidade
const OURO := "#ffc65a"       # Kael: luz dourada da Ordem
const OURO_VIVO := "#ffcf55"
const ACO := "#86c8ff"        # Kael: aço frio das habilidades
const VENTO := "#6fe24a"      # Lyra: vento verde
const FLECHA := "#cfeaff"
const DOURADA := "#ffd23f"    # Lyra: flecha dourada
const ARCANO := "#59d0ff"     # Oren: azul arcano
const VIOLETA := "#b58cff"
const FOGO := "#ff8a3d"

static func _ponta(h) -> Vector2:
	var v: Vector2 = h.view.para_jogo(h.view.boneco.ponta_arma())
	return Vector2(h.cx(), h.y + h.h) + v

## Clarão de disparo na ponta do arco: reflexo, anel de vento e, nos tiros fortes, um jato de energia.
static func disparo(h, cor, forte := false, dir := Vector2.ZERO) -> void:
	var g = h.game
	var d := dir if dir != Vector2.ZERO else Vector2(h.facing, 0)
	d = d.normalized()
	var p := _ponta(h) + d * 5.0
	var ang := d.angle()
	reflexo(g, p, 17.0 if forte else 10.0, cor, 8)
	var r0 := 7.0 if forte else 4.5
	fx(g, 9, func(cv: CanvasItem, k: float):
		cv.draw_set_transform(p + d * 7.0 * k, ang, Vector2(0.32, 1.0))
		cv.draw_arc(Vector2.ZERO, r0 * (0.5 + 1.4 * sai(k)), 0, TAU, 20, Gfx.col(cor, 0.9 * (1.0 - k)), 1.5 * (1.0 - k) + 0.3)
		cv.draw_set_transform_matrix(Transform2D.IDENTITY))
	if forte:
		clarao(g, p, 20.0, cor, 7)
		estocada(g, p, d, 30.0, cor, 7.0)
		if h.on_ground: g.dust(h.cx() - h.facing * 6.0, h.y + h.h, 3)

## Conjuração na ponta do cajado: círculo de runas de pé, clarão e centelhas.
static func conjuro(h, cor, r := 9.0, para_baixo := false) -> void:
	var g = h.game
	# na frente do herói, de onde o projétil sai (a ponta do cajado ainda está em movimento nessa hora)
	var p := Vector2(h.cx() + h.facing * 15.0, h.y + 11.0)
	if para_baixo: p = Vector2(h.cx() + h.facing * 5.0, h.y + h.h + 3.0)
	circulo_runas(g, p, r, cor, 14, Vector2(1.0, 0.36) if para_baixo else Vector2(0.36, 1.0), 1.6, 5)
	clarao(g, p, r * 1.6, cor, 7)
	centelhas(g, p, 2, cor, r * 0.6, 1.0)

## Investida de escudo: barreira de energia na frente do herói e riscos de vento atrás, acompanhando a corrida.
static func investida(h, cor, vida := 12, hab := -1) -> void:
	var g = h.game
	var barreira := func(cv: CanvasItem, k: float):
		if is_instance_valid(h):
			var f: int = h.facing
			meia_lua(cv, Vector2(h.cx() + f * 8.0, h.y + 12.0), 18.0, -1.25, 1.25, 12.0, cor, 0.9 * (1.0 - pow(k, 2.0)), Vector2(f, 1))
	var vento := func(cv: CanvasItem, k: float):
		if is_instance_valid(h):
			var f: int = h.facing
			var c := Vector2(h.cx(), h.y + 12.0)
			for i in 4:
				var yy := c.y - 10.0 + i * 6.5 + sin(i * 2.3) * 2.0
				var comp := 22.0 + 12.0 * fposmod(i * 0.618 + k * 3.0, 1.0)
				brilho(cv, Vector2(c.x - f * (8.0 + comp * 0.5), yy), comp, cor, 0.6 * (1.0 - k), Vector2(1.0, 0.035))
			brilho(cv, c + Vector2(f * 13.0, 0), 22.0, cor, 0.45 * (1.0 - k))
	if hab >= 0:
		fx_hab(h, hab, vida, barreira, "energia"); fx_hab(h, hab, vida, vento)
	else:
		fx(g, vida, barreira, "energia"); fx(g, vida, vento)

## Mergulho com a espada: rastro de energia acima do herói enquanto ele cai.
static func queda(h, cor) -> void:
	fx(h.game, 40, func(cv: CanvasItem, k: float):
		if is_instance_valid(h) and h.mv == "mergulho":
			var c := Vector2(h.cx() + h.facing * 6.0, h.y + 14.0)
			feixe(cv, c + Vector2(0, 9), c - Vector2(h.facing * 4.0, 48.0), 13.0, 1.0, cor, 0.85, 1.0), "energia")

## Pouso do mergulho: onda de choque no chão e coluna curta de luz.
static func pouso(h) -> void:
	var pe := Vector2(h.cx(), h.y + h.h)
	onda_chao(h.game, pe, 42.0, ACO, true)
	coluna(h.game, pe.x, pe.y, 40.0, 15.0, ACO, 12)

## Efeito de cada golpe básico, no instante do acerto. Chamado por hero.attack_hit.
static func golpe(h, i: int) -> void:
	var g = h.game
	var f: int = h.facing
	var c := Vector2(h.cx(), h.y + 12.0)
	var pe := Vector2(h.cx(), h.y + h.h)
	var mv: String = h.mv
	match String(h.d.id):
		"guardiao":
			match mv:
				"g1", "ar1": lamina(g, c + Vector2(f * 12, -2), f, 16.0, -1.5, 0.9, OURO, 8, 8.0, 9.0)
				"g2", "ar2": lamina(g, c + Vector2(f * 12, -1), f, 16.0, 1.2, -1.3, OURO, 8, 8.0, 9.0)
				"g3": estocada(g, c + Vector2(f * 6, -1), Vector2(f, 0), 36.0, OURO)
				"g4":
					lamina(g, c + Vector2(f * 12, -3), f, 22.0, -1.9, 1.3, OURO, 11, 12.0, 10.0)
					if h.on_ground:
						onda_chao(g, pe + Vector2(f * 26, 0), 24.0, OURO)
						reflexo(g, pe + Vector2(f * 26, -4), 17.0, OURO, 8)
				"lanca":
					lamina(g, c + Vector2(f * 12, 2), f, 20.0, 1.4, -1.6, OURO, 10, 10.0, 2.0)
					coluna(g, pe.x + f * 16, pe.y, 54.0, 9.0, OURO, 14)
				"corrida": investida(h, OURO, 12)
				"ar3": lamina(g, c + Vector2(f * 11, 0), f, 21.0, -1.8, 1.5, OURO, 10, 12.0, 4.0)
				"mergulho": queda(h, ACO)
				"contra":
					selo_rosacea(g, c + Vector2(f * 16, -2), 24.0, OURO_VIVO, 18)
					lamina(g, c + Vector2(f * 12, 0), f, 24.0, 1.3, -1.7, OURO_VIVO, 12, 13.0, 8.0)
					reflexo(g, c + Vector2(f * 25, -5), 15.0, "#fff3c8", 9)
		"cacadora":
			match mv:
				"g1", "g2", "ar1", "ar2": disparo(h, FLECHA)
				"g3": lamina(g, c + Vector2(f * 8, 4), f, 13.0, 1.5, -0.4, VENTO, 8, 7.0, 6.0)
				"g4", "ar3": disparo(h, DOURADA, true)
				"lanca":
					lamina(g, c + Vector2(f * 9, 2), f, 17.0, 1.5, -1.6, VENTO, 10, 9.0, 2.0)
					estocada(g, c + Vector2(f * 9, 2), Vector2(f * 0.22, -1), 34.0, VENTO, 7.0)
				"corrida":
					if i == 0:
						lamina(g, pe + Vector2(f * 6, -4), f, 18.0, 2.2, -0.4, VENTO, 9, 8.0, 8.0, Vector2(1.0, 0.4))
						g.dust(pe.x, pe.y, 4)
					else:
						lamina(g, c + Vector2(f * 9, 2), f, 15.0, 1.4, -1.4, VENTO, 9, 8.0)
				"mergulho": disparo(h, VENTO, true, Vector2(f * 0.1, 1))
		_:
			match mv:
				"g1":
					lamina(g, c + Vector2(f * 13, -3), f, 17.0, -1.5, 0.9, ARCANO, 8, 7.0, 9.0)
					centelhas(g, c + Vector2(f * 20, 0), 3, VIOLETA, 9.0)
				"g2":
					lamina(g, c + Vector2(f * 13, -1), f, 17.0, 1.2, -1.3, ARCANO, 8, 7.0, 9.0)
					centelhas(g, c + Vector2(f * 20, -6), 3, VIOLETA, 9.0)
				"g3", "ar1", "ar2": conjuro(h, ARCANO, 9.0)
				"ar3": conjuro(h, ARCANO, 13.0)
				"g4":
					conjuro(h, ARCANO, 11.0)
					circulo_runas(g, Vector2(h.cx() + f * 30, pe.y), 28.0, ARCANO, 22)
				"lanca":
					conjuro(h, ARCANO, 10.0)
					circulo_runas(g, Vector2(h.cx() + f * 30, pe.y), 22.0, ARCANO, 24)
				"corrida":
					explosao(g, c + Vector2(f * 22, -2), 15.0, ARCANO, false)
					estocada(g, c + Vector2(f * 4, -2), Vector2(f, 0), 30.0, ARCANO, 8.0)
				"mergulho": conjuro(h, FOGO, 11.0, true)

## Pilar de runas do Oren.
static func pilar(g, px: float, base: float) -> void:
	coluna(g, px, base, 66.0, 20.0, ARCANO, 18)
	centelhas(g, Vector2(px, base - 30.0), 6, "#9ff0ff", 14.0, 1.6)
	brasas(g, Vector2(px, base - 10.0), 5, ARCANO, 1.6, 6.0)

## Flecha da chuva que chega ao chão: respingo de luz.
static func flecha_no_chao(g, o: Dictionary) -> void:
	if o.y + o.h < GameData.GROUND - 3.0:
		return
	var p := Vector2(o.x + o.w / 2.0, GameData.GROUND)
	fx(g, 10, func(cv: CanvasItem, k: float):
		brilho(cv, p, 13.0, VENTO, 0.65 * (1.0 - k), Vector2(1.0, 0.35))
		cv.draw_set_transform(p, 0.0, Vector2(1.0, 0.3))
		cv.draw_arc(Vector2.ZERO, 3.0 + 12.0 * sai(k), 0, TAU, 18, Gfx.col(VENTO, 0.9 * (1.0 - k)), 1.2)
		cv.draw_set_transform_matrix(Transform2D.IDENTITY))
	# a flecha fica cravada um instante, soltando um fio de vento para cima
	fx(g, 9, func(cv: CanvasItem, k: float):
		feixe(cv, p, p - Vector2(1.5, 20.0 * (0.5 + 0.5 * sai(k))), 5.0 * (1.0 - k), 0.5, VENTO, 0.9 * (1.0 - k), 1.0 - k), "energia")
	centelhas(g, p - Vector2(0, 2), 2, VENTO, 5.0, 1.0)
	if randf() < 0.5: g.dust(p.x, p.y, 1)

static func feixe_luz(cv: CanvasItem, p0: Vector2, p1: Vector2, cor, a: float) -> void:
	cv.draw_line(p0, p1, Gfx.col(cor, a), 1.4)
	cv.draw_line(p0, p1, Color(1, 1, 1, a * 0.8), 0.6)

## Elo da Corrente de Raios: relâmpago vivo até o alvo e estouro elétrico nele.
static func corrente(g, p0: Vector2, p1: Vector2) -> void:
	relampago(g, p0, p1, "#9ff0ff", 16, 1.9, 2)
	clarao(g, p1, 15.0, ARCANO, 8)
	fx(g, 11, func(cv: CanvasItem, k: float): anel(cv, p1, 6.0 + 16.0 * sai(k), 4.5 * (1.0 - k), ARCANO, 0.85 * (1.0 - k)), "energia")
	centelhas(g, p1, 4, "#e6fdff", 10.0, 1.6)
	# faíscas elétricas que ficam estalando no alvo
	var sem := randi() % 9999
	fx(g, 22, func(cv: CanvasItem, k: float):
		var passo := int(k * 11.0)
		if passo % 2 == 0:
			var rng := RandomNumberGenerator.new(); rng.seed = sem + passo
			var a := Vector2(rng.randf_range(-10, 10), rng.randf_range(-12, 12))
			var b := Vector2(rng.randf_range(-10, 10), rng.randf_range(-12, 12))
			raio(cv, caminho_raio(p1 + a, p1 + b, sem + passo * 7, 0.3, 3), "#9ff0ff", 1.0 - k, 0.9))

## Queda do meteoro: coluna de fogo, onda no chão, pedras, fumaça e clarão na tela.
static func meteoro_impacto(g, px: float) -> void:
	var chao := GameData.GROUND
	coluna(g, px, chao, 175.0, 46.0, "#ff6a2a", 26)
	onda_chao(g, Vector2(px, chao), 112.0, "#ffb347", true)
	lascas(g, Vector2(px, chao), 12, 4.6)
	fumaca(g, Vector2(px, chao - 20.0), 9, 12.0, 46.0)
	raios_de_luz(g, Vector2(px, chao - 24.0), "#ffd9a0", 12, 150.0, 18)
	tela(g, "#ffd9a0", 0.3, 8)

## Começo de cada habilidade. Chamado por hero.skill_start.
static func habilidade_inicio(h, i: int) -> void:
	var g = h.game
	var f: int = h.facing
	var c := Vector2(h.cx(), h.y + 12.0)
	var pe := Vector2(h.cx(), h.y + h.h)
	match String(h.d.id):
		"guardiao":
			if i == 0:
				investida(h, OURO_VIVO, 18, 0)
				clarao(g, c + Vector2(f * 10, 0), 26.0, OURO_VIVO, 8)
				onda_chao(g, pe, 22.0, OURO_VIVO)
			elif i == 1:
				onda_chao(g, pe, 32.0, ACO, true)
				coluna(g, pe.x + f * 8, pe.y, 100.0, 16.0, ACO, 20)
				# a meia-lua sobe junto com o herói
				fx_hab(h, 1, 18, func(cv: CanvasItem, k: float):
					if is_instance_valid(h):
						var varre := minf(1.0, k * 4.0)
						meia_lua(cv, Vector2(h.cx() + h.facing * 10.0, h.y + 10.0), 27.0, 1.5, lerpf(1.5, -1.8, varre), 14.0 * (1.0 - 0.3 * k), ACO, 0.9 * (1.0 - pow(k, 1.6)), Vector2(h.facing, 1)), "energia")
				reflexo(g, c + Vector2(f * 14, -10), 22.0, "#ffffff", 9)
			else:
				tempestade(h)
		"cacadora":
			if i == 1:
				onda_chao(g, pe, 18.0, VENTO)
		_:
			# círculo de conjuração sob os pés enquanto a magia é preparada
			var cor: String = h.d.skills[i].c
			circulo_runas(g, pe, 22.0 + i * 6.0, cor, int(h.d.skills[i].dur), Vector2(1.0, 0.32), 1.0, 6 + i)
			fx(g, 10 + i * 2, func(cv: CanvasItem, k: float):
				if is_instance_valid(h):
					var p := _ponta(h)
					brilho(cv, p, 6.0 + 12.0 * k, cor, 0.5 + 0.4 * k)
					brilho(cv, p, 2.0 + 5.0 * k, Color.WHITE, 0.9))

## Tempestade de Aço: três lâminas de energia giram em volta do herói, em dois andares, com a rosácea no chão.
static func tempestade(h) -> void:
	fx_hab(h, 2, 60, func(cv: CanvasItem, k: float):
		if is_instance_valid(h):
			var c := Vector2(h.cx(), h.y + 11.0)
			var entra := minf(1.0, k * 8.0) * minf(1.0, (1.0 - k) * 10.0)
			var rot := k * 60.0 * 0.5
			for j in 3:
				var a0 := rot + j * TAU / 3.0
				meia_lua(cv, c, 42.0, a0, a0 + 1.7, 15.0, "#6ab4ff", 0.92 * entra, Vector2(1.0, 0.36))
				meia_lua(cv, c + Vector2(0, -9), 27.0, -a0 * 1.3, -a0 * 1.3 + 1.5, 10.0, "#a8d4ff", 0.8 * entra, Vector2(1.0, 0.36)), "energia")
	fx_hab(h, 2, 62, func(cv: CanvasItem, k: float):
		if is_instance_valid(h):
			var pe := Vector2(h.cx(), h.y + h.h)
			var a := minf(1.0, k * 8.0) * minf(1.0, (1.0 - k) * 8.0)
			rosacea(cv, pe, 40.0, "#6ab4ff", 0.75 * a, k * 5.0, 0.3)
			brilho(cv, pe, 46.0, "#6ab4ff", 0.3 * a, Vector2(1.0, 0.32)))

## Passo a passo de cada habilidade. Chamado por hero.skill_update.
static func habilidade_passo(h, i: int, t: int) -> void:
	var g = h.game
	var f: int = h.facing
	var c := Vector2(h.cx(), h.y + 12.0)
	var pe := Vector2(h.cx(), h.y + h.h)
	match String(h.d.id):
		"guardiao":
			if i == 0:
				if t < 15 and t % 3 == 0 and h.on_ground: g.dust(pe.x - f * 6.0, pe.y, 2)
			elif i == 1:
				if t < 16 and t % 2 == 0: brasas(g, c + Vector2(f * 10, 4), 1, ACO, 1.0, 8.0)
			else:
				if t < 60:
					if t % 5 == 0:
						# poeira e centelhas puxadas pelo giro
						var lado := 1.0 if (t / 5) % 2 == 0 else -1.0
						g.parts.append({"x": pe.x + lado * 44.0, "y": pe.y - 2.0, "vx": -lado * 3.2, "vy": -0.5, "life": 13.0, "vida": 13.0, "c": "#b9b2e0", "s": 2.0, "g": -0.02, "d": 0.93, "po": true})
						centelhas(g, c + Vector2(randf_range(-36, 36), randf_range(-14, 8)), 1, "#cfe6ff", 2.0, 0.8)
				elif t == 62:
					selo_rosacea(g, c + Vector2(0, -4), 60.0, OURO_VIVO, 26)
					onda_chao(g, pe, 78.0, "#6ab4ff", true)
					raios_de_luz(g, c, "#a8d4ff", 10, 110.0, 18)
		"cacadora":
			if i == 0 and t == 6:
				disparo(h, VENTO, true)
			elif i == 1 and t == 9:
				disparo(h, DOURADA, true)
				var p := _ponta(h)
				clarao(g, p, 34.0, DOURADA, 9)
				estocada(g, p, Vector2(f, 0), 84.0, DOURADA, 12.0)
				tela(g, DOURADA, 0.12, 5)
			elif i == 2 and t == 10:
				# o tiro sobe ao céu e a área da chuva acende no chão
				var p2 := _ponta(h)
				estocada(g, p2, Vector2(f * 0.16, -1), 150.0, VENTO, 9.0)
				clarao(g, p2, 22.0, VENTO, 8)
				var meio := Vector2(h.cx() + f * 105.0, GameData.GROUND)
				fx(g, 84, func(cv: CanvasItem, k: float):
					var a := minf(1.0, k * 8.0) * minf(1.0, (1.0 - k) * 6.0)
					var pulso := 0.75 + 0.25 * sin(k * 60.0)
					brilho(cv, meio, 132.0, VENTO, 0.3 * a * pulso, Vector2(1.0, 0.11))
					cv.draw_set_transform(meio, 0.0, Vector2(1.0, 0.1))
					cv.draw_arc(Vector2.ZERO, 126.0, 0, TAU, 48, Gfx.col(VENTO, 0.7 * a), 1.2)
					cv.draw_arc(Vector2.ZERO, 118.0 - 10.0 * fposmod(k * 6.0, 1.0), 0, TAU, 48, Gfx.col(VENTO, 0.35 * a), 0.9)
					cv.draw_set_transform_matrix(Transform2D.IDENTITY))
		_:
			if i == 0 and t == 8:
				conjuro(h, FOGO, 13.0)
			elif i == 1 and t == 10:
				conjuro(h, "#9ff0ff", 13.0)
				tela(g, "#9ff0ff", 0.12, 5)
			elif i == 2 and t == 12:
				conjuro(h, "#ff4d2e", 15.0)
				# portal de runas no céu, de onde o meteoro sai, e a marca no chão onde ele cai
				circulo_runas(g, Vector2(h.x - f * 34.0, 30.0), 44.0, "#ff6a2a", 40, Vector2(1.0, 0.42), 1.6, 7)
				circulo_runas(g, Vector2(h.x + f * 120.0 + 11.0, GameData.GROUND), 62.0, FOGO, 40, Vector2(1.0, 0.3), 1.2, 7)

## Estouro da Fúria: clarão na tela, leque de raios, ondas e o emblema de cada classe.
static func furia(h) -> void:
	var g = h.game
	var cor: String = GameData.FURIA[h.d.id].c
	var c := Vector2(h.cx(), h.y + h.h / 2.0)
	var pe := Vector2(h.cx(), h.y + h.h)
	tela(g, "#ffffff", 0.32, 8)
	raios_de_luz(g, c, cor, 18, 280.0, 34)
	for j in 3:
		var r1 := 60.0 + j * 75.0
		fx(g, 16 + j * 4, func(cv: CanvasItem, k: float): anel(cv, c, r1 * (0.2 + 0.8 * sai(k, 2.5)), 15.0 * (1.0 - 0.6 * k), cor, 0.9 * (1.0 - pow(k, 1.5))), "energia")
	onda_chao(g, pe, 150.0, cor, true)
	coluna(g, pe.x, pe.y, 190.0, 34.0, cor, 30)
	brasas(g, c, 26, cor, 4.0, 20.0)
	match String(h.d.id):
		"guardiao":
			selo_rosacea(g, c + Vector2(0, -10), 78.0, cor, 36)
		"cacadora":
			# olho da tempestade: anéis de vento subindo em volta dela
			for j in 5:
				var alt := j * 15.0
				var total := 20.0 + j * 4.0
				fx(g, int(total), func(cv: CanvasItem, k: float):
					anel(cv, pe + Vector2(0, -alt - 30.0 * k), (26.0 + j * 9.0) * (0.5 + 0.7 * sai(k)), 9.0 * (1.0 - 0.5 * k), cor, 1.0 - pow(k, 1.6), Vector2(1.0, 0.28)), "energia")
		_:
			# eclipse: disco escuro com coroa de luz e runas em volta
			fx(g, 40, func(cv: CanvasItem, k: float):
				var a := minf(1.0, k * 6.0) * (1.0 - k * k)
				var p := c + Vector2(0, -52)
				brilho(cv, p, 46.0, cor, 0.8 * a)
				runas(cv, p, 40.0, cor, a, k * 3.0, Vector2.ONE, 7))
			fx(g, 40, func(cv: CanvasItem, k: float):
				var a := minf(1.0, k * 6.0) * (1.0 - k * k)
				cv.draw_circle(c + Vector2(0, -52), 17.0, Color(0.03, 0.01, 0.08, a)), "normal")
