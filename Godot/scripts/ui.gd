class_name Ui
extends RefCounted
## Peças da interface em estilo gótico: fontes, painéis com filete dourado, barras, botões e ícones.

const OURO := Color("#e3c26a")
const OURO_ESC := Color("#8a6a2c")
const TINTA := Color("#0b0914")
const ROXO := Color("#231a3d")
const CLARO := Color("#efe6d2")
const APAGADO := Color("#8d86a3")
const SANGUE := Color("#c0303a")

static var _tit: Font
static var _txt: Font
static var _neg: Font
static var _deco: Font

static func tit() -> Font:
	if _tit == null:
		var v := FontVariation.new()
		v.base_font = load("res://assets/fontes/Cinzel.ttf")
		v.variation_opentype = {"wght": 700}
		_tit = v
	return _tit

static func deco() -> Font:
	if _deco == null: _deco = load("res://assets/fontes/CinzelDecorative-Bold.ttf")
	return _deco

static func fonte() -> Font:
	if _txt == null: _txt = load("res://assets/fontes/AlegreyaSans-Medium.ttf")
	return _txt

static func neg() -> Font:
	if _neg == null: _neg = load("res://assets/fontes/AlegreyaSans-Bold.ttf")
	return _neg

static func cor(v, a := 1.0) -> Color:
	var c: Color = v if v is Color else Color(v)
	c.a *= a
	return c

## Texto com contorno escuro. align: 0 esquerda, 1 centro, 2 direita. `y` é o meio da linha.
static func txt(c: CanvasItem, s: String, x: float, y: float, v = CLARO, size := 8, align := 0, a := 1.0, f: Font = null, borda := 2) -> void:
	if f == null: f = fonte()
	var tw: float = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var ox := x
	if align == 1: ox = x - tw / 2.0
	elif align == 2: ox = x - tw
	var p := Vector2(ox, y + size * 0.34)
	if borda > 0:
		c.draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, borda, Color(0.02, 0.01, 0.05, a * 0.9))
	c.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, cor(v, a))

static func titulo(c: CanvasItem, s: String, x: float, y: float, v = OURO, size := 12, align := 1, a := 1.0) -> void:
	txt(c, s, x, y, v, size, align, a, tit(), 3)

static func largura(s: String, size: int, f: Font = null) -> float:
	if f == null: f = fonte()
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

static func losango(c: CanvasItem, p: Vector2, r: float, v, a := 1.0) -> void:
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)]), cor(v, a))

## Retângulo com degradê vertical.
static func grad(c: CanvasItem, r: Rect2, a: Color, b: Color) -> void:
	c.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([a, a, b, b]))

## Retângulo com degradê horizontal.
static func grad_h(c: CanvasItem, r: Rect2, a: Color, b: Color) -> void:
	c.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([a, b, b, a]))

## Painel escuro com filete dourado e losangos nos cantos.
static func painel(c: CanvasItem, r: Rect2, a := 0.9, destaque := false) -> void:
	grad(c, r, cor("#1c1532", a), cor("#0a0814", a))
	var o := OURO if destaque else OURO_ESC
	c.draw_rect(r, cor(o, 0.95), false, 0.7)
	c.draw_rect(r.grow(-1.6), cor(o, 0.25), false, 0.4)
	for p in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		losango(c, p, 2.2, TINTA); losango(c, p, 1.5, o)

## Linha ornamental: filete que some nas pontas com um losango no meio.
static func filete(c: CanvasItem, x: float, y: float, w: float, a := 1.0) -> void:
	var m := x + w / 2.0
	c.draw_polygon(PackedVector2Array([Vector2(x, y), Vector2(m, y - 0.4), Vector2(x + w, y), Vector2(m, y + 0.4)]),
		PackedColorArray([cor(OURO, 0), cor(OURO, a), cor(OURO, 0), cor(OURO, a)]))
	losango(c, Vector2(m, y), 2.0, OURO, a); losango(c, Vector2(m, y), 0.9, TINTA, a)

## Barra com moldura. `rastro` é a fração antiga, mostrada clara por baixo (dano recente).
static func barra(c: CanvasItem, r: Rect2, k: float, ca: Color, cb: Color, rastro := -1.0, fundo := Color("#120a14")) -> void:
	c.draw_rect(r.grow(0.8), cor(TINTA, 0.95))
	c.draw_rect(r, fundo)
	k = clampf(k, 0.0, 1.0)
	if rastro > k:
		c.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(rastro, 0, 1), r.size.y)), Color(1, 0.92, 0.75, 0.75))
	if k > 0:
		var f := Rect2(r.position, Vector2(r.size.x * k, r.size.y))
		grad(c, f, ca, cb)
		c.draw_rect(Rect2(f.position, Vector2(f.size.x, maxf(0.6, r.size.y * 0.28))), Color(1, 1, 1, 0.28))
	c.draw_rect(r.grow(0.8), cor(OURO_ESC, 0.9), false, 0.5)

static func botao(c: CanvasItem, r: Rect2, rotulo: String, sel: bool, travado := false, t := 0) -> void:
	if sel:
		grad_h(c, r, cor("#5a3f9a", 0.95), cor("#2a1d52", 0.25))
		c.draw_rect(Rect2(r.position, Vector2(1.5, r.size.y)), OURO)
		var px := r.position.x - 5.0 + sin(t * 0.15) * 1.2
		losango(c, Vector2(px, r.position.y + r.size.y / 2), 2.4, OURO)
	else:
		grad_h(c, r, cor("#151026", 0.8), cor("#151026", 0.05))
	var cc = APAGADO.darkened(0.3) if travado else (Color.WHITE if sel else CLARO.darkened(0.12))
	txt(c, rotulo, r.position.x + 8, r.position.y + r.size.y / 2, cc, 9, 0, 1.0, tit())
	if travado:
		txt(c, "em breve", r.end.x - 4, r.position.y + r.size.y / 2, APAGADO.darkened(0.2), 5, 2)

## Tecla desenhada (para dicas de controle).
static func tecla(c: CanvasItem, s: String, x: float, y: float, size := 6) -> float:
	var w := maxf(size + 3.0, largura(s, size, neg()) + 4.0)
	var r := Rect2(x, y - size * 0.75, w, size * 1.5)
	c.draw_rect(r, Color("#2a2540")); c.draw_rect(r, cor(CLARO, 0.7), false, 0.5)
	txt(c, s, x + w / 2, y, Color.WHITE, size, 1, 1.0, neg(), 0)
	return w

static func seta(c: CanvasItem, p: Vector2, dir: Vector2, r: float, v) -> void:
	var n := Vector2(-dir.y, dir.x)
	c.draw_colored_polygon(PackedVector2Array([p + dir * r, p - dir * r * 0.6 + n * r * 0.8, p - dir * r * 0.6 - n * r * 0.8]), cor(v))

# ---------------- Ícones das habilidades ----------------
## Desenha o ícone `id` centrado em p, cabendo num quadrado de lado s.
static func icone(c: CanvasItem, id: String, p: Vector2, s: float, v: Color, aceso := true) -> void:
	var u := s / 20.0
	var cl := v if aceso else Color("#55506a")
	var br := Color.WHITE if aceso else Color("#8a86a0")
	var P := func(pts: Array, colr: Color) -> void:
		var arr := PackedVector2Array()
		for q in pts: arr.append(p + Vector2(q[0], q[1]) * u)
		c.draw_colored_polygon(arr, colr)
	var L := func(a: Array, b: Array, colr: Color, w: float) -> void:
		c.draw_line(p + Vector2(a[0], a[1]) * u, p + Vector2(b[0], b[1]) * u, colr, w * u)
	match id:
		"escudo":
			P.call([[-6, -7], [6, -7], [6, 1], [0, 8], [-6, 1]], cl)
			P.call([[-3.5, -4.5], [3.5, -4.5], [3.5, 0.5], [0, 4.5], [-3.5, 0.5]], br)
			L.call([-9, 0], [-7, 0], br, 1.2); L.call([-9, -3], [-7.5, -3], br, 1.0); L.call([-9, 3], [-7.5, 3], br, 1.0)
		"ascendente":
			P.call([[-2, 8], [2, 8], [3, -4], [0, -9], [-3, -4]], br)
			c.draw_arc(p + Vector2(-1, 3) * u, 7 * u, -2.2, 0.3, 12, cl, 1.8 * u)
			P.call([[-4, 5], [4, 5], [4, 6.5], [-4, 6.5]], cl)
		"giro":
			c.draw_arc(p, 7 * u, 0.3, 2.8, 12, cl, 2.2 * u); c.draw_arc(p, 7 * u, 3.44, 5.94, 12, cl, 2.2 * u)
			c.draw_arc(p, 3.2 * u, 0, TAU, 12, br, 1.4 * u)
			P.call([[7, -1], [9.5, 3], [5, 3.5]], br); P.call([[-7, 1], [-9.5, -3], [-5, -3.5]], br)
		"tripla":
			for dy in [-5.0, 0.0, 5.0]:
				L.call([-8, dy * 1.2], [5, dy * 0.6], cl, 1.3)
				P.call([[8, dy * 0.5], [4, dy * 0.6 - 2.2], [4, dy * 0.6 + 2.2]], br)
		"perfurante":
			L.call([-9, 0], [5, 0], br, 2.0)
			P.call([[9.5, 0], [4, -3.5], [4, 3.5]], br)
			c.draw_arc(p + Vector2(-2, 0) * u, 5 * u, -1.2, 1.2, 8, cl, 1.5 * u); c.draw_arc(p + Vector2(-7, 0) * u, 5 * u, -1.2, 1.2, 8, cl, 1.2 * u)
		"chuva":
			for i in 4:
				var x := -7.0 + i * 4.6
				var y := -3.0 + (i % 2) * 4.0
				L.call([x + 1.5, y - 6], [x, y + 3], cl, 1.2)
				P.call([[x - 0.5, y + 6.5], [x - 2, y + 2.5], [x + 1.6, y + 3]], br)
		"orbe":
			c.draw_circle(p + Vector2(1, 1) * u, 6 * u, cl); c.draw_circle(p + Vector2(1, 1) * u, 3 * u, br)
			P.call([[-3, -3], [-8, -8], [-1, -6]], cl); P.call([[-5, 1], [-9.5, -2], [-5, -3]], cl)
		"raio":
			P.call([[2, -9], [-5, 1], [-0.5, 1], [-3, 9], [6, -2], [1, -2], [4, -9]], cl)
			P.call([[1.5, -6], [-2.5, 0], [1, 0], [0, 4], [3.5, -1], [0.5, -1]], br)
		"meteoro":
			c.draw_circle(p + Vector2(-3, 4) * u, 5 * u, cl); c.draw_circle(p + Vector2(-3.5, 4.5) * u, 2.4 * u, br)
			P.call([[0, 0], [9, -9], [2, 5]], cl); P.call([[-7, 1], [5, -9], [-2, -1]], cl)
		"esquiva":
			P.call([[-2, -6], [5, 0], [-2, 6], [0, 0]], br); P.call([[-8, -5], [-2, 0], [-8, 5], [-6, 0]], cl)
		_:
			c.draw_circle(p, 6 * u, cl)

# ---------------- Comandos de menu ----------------
static func cima() -> bool: return Input.is_action_just_pressed("ui_up")
static func baixo() -> bool: return Input.is_action_just_pressed("ui_down")
static func esq() -> bool: return Input.is_action_just_pressed("ui_left")
static func dir() -> bool: return Input.is_action_just_pressed("ui_right")
static func ok() -> bool: return Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("p1_attack")
static func volta() -> bool: return Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("p1_dash")

# ---------------- Lista de golpes (pausa e lobby) ----------------
const AJUDA := [
	[["Z"], "Combo de 4 golpes"],
	[["baixo", "Z"], "Lançador: joga o inimigo para o alto"],
	[["dir", "dir"], "Correr (toque duas vezes)"],
	[["dir", "dir", "Z"], "Golpe de corrida"],
	[["X", "Z"], "No ar: combo aéreo de 3 golpes"],
	[["X", "baixo", "Z"], "No ar: mergulho"],
	[["segure", "Z"], "Carrega a mana. Solte no nível 1, 2 ou 3"],
	[["C"], "Esquiva (atravessa golpes)"],
	[["X"], "Pular (duas vezes). Com ↓, desce da plataforma"],
	[["P"], "Pausar"],
]

## Desenha uma sequência de teclas; devolve o x final.
static func teclas(c: CanvasItem, seq: Array, x: float, y: float, size := 6) -> float:
	for tk in seq:
		if tk in ["esq", "dir", "cima", "baixo"]:
			var r := Rect2(x, y - size * 0.75, size + 3.0, size * 1.5)
			c.draw_rect(r, Color("#2a2540")); c.draw_rect(r, cor(CLARO, 0.7), false, 0.5)
			var dv: Vector2 = {"esq": Vector2.LEFT, "dir": Vector2.RIGHT, "cima": Vector2.UP, "baixo": Vector2.DOWN}[tk]
			seta(c, r.get_center(), dv, size * 0.42, Color.WHITE)
			x += r.size.x + 2.0
		elif tk == "segure":
			txt(c, "segure", x, y, OURO, size, 0)
			x += largura("segure", size) + 2.5
		else:
			x += tecla(c, tk, x, y, size) + 2.0
	return x

static func ajuda(c: CanvasItem, x: float, y: float, passo := 13.0, size := 6) -> void:
	for i in AJUDA.size():
		var yy := y + i * passo
		teclas(c, AJUDA[i][0], x, yy, size)
		txt(c, String(AJUDA[i][1]).replace("↓", "baixo"), x + 52, yy, CLARO, size)
