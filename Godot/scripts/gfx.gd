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

## Estrela de impacto (4 pontas) com anel, para cada golpe que acerta.
static func impacto(c: CanvasItem, px: float, py: float, cor, k: float, tam: float) -> void:
	var a := 1.0 - k
	var r := tam * (0.6 + k * 0.9)
	c.draw_arc(Vector2(px, py), r, 0, TAU, 20, col(cor, a * 0.8), 1.5 * a + 0.5)
	var pts := PackedVector2Array()
	for i in 8:
		var ang := i * PI / 4 + 0.4
		var d := (tam * 1.4 * (1.0 - k * 0.5)) if i % 2 == 0 else tam * 0.28
		pts.append(Vector2(px, py) + Vector2(cos(ang), sin(ang)) * d)
	c.draw_colored_polygon(pts, col(cor, a))
	c.draw_circle(Vector2(px, py), tam * 0.35 * a, Color(1, 1, 1, a))
