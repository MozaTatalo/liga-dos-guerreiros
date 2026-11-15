class_name Gfx
extends RefCounted
## Desenho de efeitos feito em código (cortes de luz, impactos) e atalhos de desenho.

static func col(v, a := 1.0) -> Color:
	var c: Color = v if v is Color else Color(v)
	c.a *= a
	return c

static func rect(c: CanvasItem, x: float, y: float, w: float, h: float, v, a := 1.0) -> void:
	c.draw_rect(Rect2(x, y, w, h), col(v, a))

static func tri(c: CanvasItem, a: Vector2, b: Vector2, d: Vector2, v, al := 1.0) -> void:
	c.draw_colored_polygon(PackedVector2Array([a, b, d]), col(v, al))

static func text(c: CanvasItem, s: String, x: float, y: float, v = "#ffffff", size := 8, align := 0, a := 1.0) -> void:
	Ui.txt(c, s, x, y, v, size, align, a)

static func slash(c: CanvasItem, cx: float, cy: float, f: int, r: float, s: int, k: float, v) -> void:
	# lâmina de luz em meia-lua: borda colorida, miolo branco, afina nas pontas e some abrindo
	c.draw_set_transform(Vector2(cx, cy), 0.0, Vector2(f, 1))
	var a0 := -1.3 if s != 1 else 0.9
	var a1 := 1.0 if s != 1 else -1.2
	var rr := r * (1.0 + k * 0.28)
	var th := r * 0.5 * (1.0 - k * 0.6)
	var fora := PackedVector2Array()
	var dentro := PackedVector2Array()
	var n := 18
	for i in n + 1:
		var u := i / float(n)
		var a := lerpf(a0, a1, u)
		var t := sin(PI * pow(u, 0.8))
		fora.append(Vector2(cos(a), sin(a)) * rr)
		dentro.append(Vector2(cos(a), sin(a)) * (rr - th * t))
	var alfa := 1.0 - k
	var cor := col(v, alfa)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in n:
		var q := PackedVector2Array([fora[i], fora[i + 1], dentro[i + 1], dentro[i]])
		var u := i / float(n)
		var brilho := Color(1, 1, 1, alfa * (0.35 + 0.65 * sin(PI * u)))
		c.draw_polygon(q, PackedColorArray([cor, cor, brilho, brilho]))
	c.draw_polyline(fora, Color(1, 1, 1, alfa * 0.9), 1.2)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

## Impacto em três camadas, animado "em degraus" (segura cada desenho por dois quadros, como efeito desenhado à mão):
## clarão quase branco no primeiro instante, riscos finos que abrem (mais para o lado do golpe) e anel que afina.
static func impacto(c: CanvasItem, px: float, py: float, cor, k: float, tam: float, dir := 0, semente := 0.0) -> void:
	k = floorf(k * 5.0) / 5.0
	var o := Vector2(px, py)
	var a := 1.0 - k
	var base: Color = col(cor)
	if k < 0.21:
		# clarão: losango branco grande, só no começo
		var r0 := tam * 0.5
		c.draw_colored_polygon(PackedVector2Array([o + Vector2(0, -r0), o + Vector2(r0 * 2.6, 0), o + Vector2(0, r0), o + Vector2(-r0 * 2.6, 0)]), Color(1, 1, 1, 0.9))
		c.draw_colored_polygon(PackedVector2Array([o + Vector2(0, -r0 * 2.2), o + Vector2(r0 * 0.5, 0), o + Vector2(0, r0 * 2.2), o + Vector2(-r0 * 0.5, 0)]), Color(1, 1, 1, 0.9))
		c.draw_circle(o, tam * 0.75, Color(base.r, base.g, base.b, 0.35))
	# riscos: agulhas de luz que saem do centro e afinam
	var n := 7
	for i in n:
		var ang := semente + i * TAU / n + sin(semente * 7.0 + i * 3.1) * 0.35
		var v := Vector2(cos(ang), sin(ang) * 0.8)
		if dir != 0: v = (v + Vector2(dir * 0.9, -0.1)).normalized()
		var comp := tam * (1.3 + 1.1 * fposmod(semente * 3.7 + i * 0.37, 1.0))
		var p0 := o + v * comp * (0.25 + k * 1.3)
		var p1 := o + v * comp * (0.9 + k * 1.9)
		var lat := Vector2(-v.y, v.x) * tam * 0.14 * a
		c.draw_colored_polygon(PackedVector2Array([p0, (p0 + p1) * 0.5 + lat, p1, (p0 + p1) * 0.5 - lat]), Color(lerpf(base.r, 1.0, 0.5), lerpf(base.g, 1.0, 0.5), lerpf(base.b, 1.0, 0.5), a))
	# anel que abre afinando
	c.draw_arc(o, tam * (0.7 + k * 1.6), 0, TAU, 24, Color(base.r, base.g, base.b, a * 0.3), 1.0 * a + 0.3)

const RASTRO_VIDA := 7.0   # quadros que cada pedaço do rastro dura

## Rastro de luz da arma: uma fita que segue a lâmina de verdade, com a ponta acesa, e some afinando.
## Os pontos são alisados (Catmull-Rom) e a fita inteira vai num desenho só.
static func rastro(c: CanvasItem, r: Dictionary) -> void:
	var pts: Array = r.pts
	var n := pts.size()
	if n < 2:
		return
	var cor: Color = r.c
	var SUB := 3
	var bases := PackedVector2Array()
	var pontas := PackedVector2Array()
	var alfas := PackedFloat32Array()
	for i in n - 1:
		var a: Array = pts[maxi(i - 1, 0)]
		var b: Array = pts[i]
		var d: Array = pts[i + 1]
		var e: Array = pts[mini(i + 2, n - 1)]
		for j in SUB:
			var u := float(j) / SUB
			var k: float = lerpf(b[2], d[2], u) / RASTRO_VIDA        # 0 = recém-criado, 1 = sumindo
			var ponta: Vector2 = (b[1] as Vector2).cubic_interpolate(d[1], a[1], e[1], u)
			var base: Vector2 = (b[0] as Vector2).cubic_interpolate(d[0], a[0], e[0], u)
			pontas.append(ponta)
			bases.append(base.lerp(ponta, 0.58 + 0.4 * k))        # a cauda afina em direção à ponta
			alfas.append(pow(1.0 - k, 1.4))
	var ult: Array = pts[n - 1]
	pontas.append(ult[1]); bases.append((ult[0] as Vector2).lerp(ult[1], 0.58 + 0.4 * ult[2] / RASTRO_VIDA)); alfas.append(pow(1.0 - ult[2] / RASTRO_VIDA, 1.4))
	# três fileiras de vértices: base (transparente), meio (cor) e ponta (branco)
	var vs := PackedVector2Array()
	var cs := PackedColorArray()
	var idx := PackedInt32Array()
	var m := pontas.size()
	for i in m:
		var al := alfas[i]
		vs.append(bases[i]); cs.append(Color(cor.r, cor.g, cor.b, 0.0))
		vs.append(bases[i].lerp(pontas[i], 0.55)); cs.append(Color(cor.r, cor.g, cor.b, al * 0.6))
		vs.append(pontas[i]); cs.append(Color(lerpf(cor.r, 1.0, 0.75), lerpf(cor.g, 1.0, 0.75), lerpf(cor.b, 1.0, 0.75), al))
	for i in m - 1:
		var o := i * 3
		idx.append_array(PackedInt32Array([o, o + 1, o + 4, o, o + 4, o + 3, o + 1, o + 2, o + 5, o + 1, o + 5, o + 4]))
	RenderingServer.canvas_item_add_triangle_array(c.get_canvas_item(), idx, vs, cs)
