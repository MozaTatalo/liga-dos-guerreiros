extends Node2D
## Menus do jogo: título, lobby com o herói em destaque, seleção de personagem, seleção de fase, golpes e opções.

signal jogar

const LOBBY := [["JOGAR", "fases"], ["PERSONAGENS", "herois"], ["GOLPES", "golpes"], ["OPÇÕES", "opcoes"],
	["EQUIPAMENTOS", ""], ["HABILIDADES", ""], ["LOJA", ""]]

var bg
var tela := "titulo"
var t := 0
var tt := 0                 # passos desde que a tela abriu (para as entradas animadas)
var sel := 0                # item do lobby
var op_sel := 0
var views: Array[HeroView] = []
var frente: Node2D
var heroi := 0
var fase := 0
var dif := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	heroi = clampi(int(Save.d.sel), 0, GameData.CLASSES.size() - 1)
	fase = int(Save.d.fase); dif = int(Save.d.dif)
	for i in GameData.CLASSES.size():
		var v := HeroView.new(GameData.CLASSES[i], 640)
		add_child(v)
		views.append(v)
	frente = Node2D.new()
	frente.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	frente.draw.connect(_frente)
	add_child(frente)
	Som.tema("menu")
	_arrumar()

func ir(nova: String) -> void:
	tela = nova; tt = 0
	_arrumar()

## Posiciona os bonecos conforme a tela.
func _arrumar() -> void:
	var W := GameData.W
	for i in views.size():
		var v := views[i]
		v.visible = true
		v.virado = 1
		v.modulate = Color.WHITE
		match tela:
			"titulo":
				v.position = Vector2(W / 2 + (i - 1) * 62, 252 - (10 if i == 0 else 0)); v.scale = Vector2.ONE * (2.0 if i == 0 else 1.7)
				v.virado = 1 if i != 2 else -1
				v.position.x = W / 2 + [0, -70, 70][i]
				v.z_index = 1 if i == 0 else 0
			"lobby", "golpes", "opcoes":
				v.visible = i == heroi
				v.position = Vector2(268, 246); v.scale = Vector2.ONE * 3.1; v.z_index = 0
				if tela != "lobby": v.modulate = Color(0.45, 0.42, 0.6)
			"herois":
				v.position = Vector2(40 + i * 104 + 48, 114); v.scale = Vector2.ONE * 1.7; v.z_index = 0
			"fases":
				v.visible = false

func _physics_process(_d: float) -> void:
	t += 1; tt += 1
	bg.cam_x = 300.0 + fmod(t * 0.25, 1600.0)
	bg.tremor = Vector2.ZERO
	bg.chefe = 0.0
	bg.queue_redraw()
	match tela:
		"titulo": _t_titulo()
		"lobby": _t_lobby()
		"herois": _t_herois()
		"fases": _t_fases()
		"opcoes": _t_opcoes()
		"golpes":
			if Ui.volta() or Ui.ok(): _som_volta(); ir("lobby")
	for i in views.size():
		var b := views[i].boneco
		if not views[i].visible: continue
		if tela == "herois":
			b.estado = "idle"
			if i == heroi:
				# o escolhido mostra os golpes em sequência
				var ciclo := (tt / 34) % 4
				if ciclo < 3 and GameData.CLASSES[i].id == "guardiao":
					b.estado = "atk"; b.passo = ciclo; b.t = minf((tt % 34) / 60.0, b.DUR[ciclo])
				else:
					b.estado = "livre"; b.taxa_livre = 14.0
					b.alvo = Hero.POSE[["tiro_pre", "tiro_pos", "conjura_pre", "conjura_pos"][ciclo]] if GameData.CLASSES[i].id != "guardiao" else Hero.POSE.vitoria
					if GameData.CLASSES[i].id == "cacadora": b.alvo = Hero.POSE.tiro_pre if (tt / 34) % 2 == 0 else Hero.POSE.tiro_pos
					elif GameData.CLASSES[i].id == "arcanista": b.alvo = Hero.POSE.conjura_pre if (tt / 34) % 2 == 0 else Hero.POSE.conjura_pos
		else:
			b.estado = "idle"
		b.vento = 0.15
		views[i].animar(1.0 / 60.0)
	queue_redraw()
	frente.queue_redraw()

func _som_move() -> void: Som.tocar("menu")
func _som_ok() -> void: Som.tocar("confirma", 0.7)
func _som_volta() -> void: Som.tocar("volta", 0.7)

func _t_titulo() -> void:
	if tt > 20 and (Ui.ok() or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_just_pressed("ui_accept")):
		_som_ok(); ir("lobby")

func _t_lobby() -> void:
	if Ui.cima(): sel = (sel + LOBBY.size() - 1) % LOBBY.size(); _som_move()
	if Ui.baixo(): sel = (sel + 1) % LOBBY.size(); _som_move()
	if Ui.ok():
		var dest: String = LOBBY[sel][1]
		if dest == "": _som_volta()
		else:
			_som_ok(); ir(dest)
	elif Ui.volta():
		_som_volta(); ir("titulo")

func _t_herois() -> void:
	var n := GameData.CLASSES.size()
	if Ui.esq(): heroi = (heroi + n - 1) % n; _som_move(); tt = 0
	if Ui.dir(): heroi = (heroi + 1) % n; _som_move(); tt = 0
	if Ui.ok() or Ui.volta():
		Save.d.sel = heroi; Save.gravar()
		_som_ok(); ir("lobby")

func liberada(d: int) -> bool:
	return d == 0 or Save.feito(GameData.FASES[fase].id, d - 1) != null

func _t_fases() -> void:
	var n := GameData.FASES.size()
	if Ui.esq(): fase = (fase + n - 1) % n; dif = 0; _som_move()
	if Ui.dir(): fase = (fase + 1) % n; dif = 0; _som_move()
	if Ui.cima() and dif > 0: dif -= 1; _som_move()
	if Ui.baixo() and dif < GameData.DIFS.size() - 1: dif += 1; _som_move()
	if Ui.ok():
		if GameData.FASES[fase].pronta and liberada(dif):
			Save.d.fase = fase; Save.d.dif = dif; Save.gravar()
			_som_ok(); jogar.emit()
		else:
			_som_volta()
	elif Ui.volta():
		_som_volta(); ir("lobby")

func _t_opcoes() -> void:
	var n := Save.OPCOES.size()
	if Ui.cima(): op_sel = (op_sel + n - 1) % n; _som_move()
	if Ui.baixo(): op_sel = (op_sel + 1) % n; _som_move()
	var lado := (1 if Ui.dir() else 0) - (1 if Ui.esq() else 0)
	var chave: String = Save.OPCOES[op_sel][0]
	if lado == 0 and Ui.ok() and Save.d.op[chave] is bool: lado = 1
	if lado != 0:
		Save.ajustar(chave, lado); _som_move()
	if Ui.volta(): _som_volta(); ir("lobby")

# ---------------- Desenho: fundo (atrás dos bonecos) ----------------
func _draw() -> void:
	var W := GameData.W
	var H := GameData.H
	match tela:
		"titulo":
			Ui.grad(self, Rect2(0, 0, W, H), Color(0.02, 0.01, 0.06, 0.55), Color(0.02, 0.01, 0.06, 0.15))
		"lobby", "golpes", "opcoes":
			Ui.grad_h(self, Rect2(0, 0, W, H), Color(0.02, 0.01, 0.06, 0.88), Color(0.02, 0.01, 0.06, 0.1))
			# pedestal de luz embaixo do herói
			draw_set_transform(Vector2(268, 247), 0.0, Vector2(1, 0.22))
			draw_circle(Vector2.ZERO, 62, Color(0.55, 0.45, 1.0, 0.16)); draw_arc(Vector2.ZERO, 62, 0, TAU, 40, Ui.cor(Ui.OURO, 0.7), 1.5)
			draw_arc(Vector2.ZERO, 54, t * 0.01, t * 0.01 + 5.0, 30, Ui.cor(Ui.OURO, 0.35), 3.0)
			draw_set_transform_matrix(Transform2D.IDENTITY)
		"herois":
			draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.01, 0.06, 0.72))
			for i in GameData.CLASSES.size() + GameData.FUTUROS.size():
				var r := Rect2(40 + i * 104, 26, 96, 118)
				var on := i == heroi
				Ui.painel(self, r, 0.92, on)
				if on:
					var c := Color(GameData.CLASSES[i].trim)
					Ui.grad(self, r.grow(-1.5), Color(c.r, c.g, c.b, 0.0), Color(c.r, c.g, c.b, 0.3))
		"fases":
			draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.01, 0.06, 0.78))

# ---------------- Desenho: interface (na frente dos bonecos) ----------------
func _frente() -> void:
	match tela:
		"titulo": _d_titulo()
		"lobby": _d_lobby()
		"herois": _d_herois()
		"fases": _d_fases()
		"opcoes": _d_lobby(true); _d_opcoes()
		"golpes": _d_lobby(true); _d_golpes()

func _d_titulo() -> void:
	var c := frente
	var W := GameData.W
	var a := clampf(tt / 40.0, 0, 1)
	var y := 62.0 - (1.0 - a) * 8
	Ui.txt(c, "LIGA DOS", W / 2, y - 26, Ui.CLARO, 15, 1, a, Ui.tit(), 3)
	Ui.txt(c, "GUERREIROS", W / 2, y, Ui.OURO, 40, 1, a, Ui.deco(), 4)
	Ui.filete(c, W / 2 - 150, y + 22, 300, a)
	Ui.txt(c, "A S   R U Í N A S   D E   A R V Á L I A", W / 2, y + 33, "#cfc4ff", 7, 1, a * 0.9, Ui.tit())
	if tt > 30 and t % 70 < 48:
		var x := W / 2 - 46
		Ui.txt(c, "Aperte", x, 258, Color.WHITE, 8, 0)
		x = Ui.teclas(c, ["Z"], x + 27, 258, 7)
		Ui.txt(c, "para começar", x + 2, 258, Color.WHITE, 8, 0)
	Ui.txt(c, "versão %s" % GameData.VERSAO, W - 6, 264, Ui.APAGADO, 5, 2)

func _topo(c: CanvasItem, titulo: String) -> void:
	var W := GameData.W
	Ui.grad(c, Rect2(0, 0, W, 22), Color(0.02, 0.01, 0.06, 0.9), Color(0.02, 0.01, 0.06, 0.0))
	Ui.txt(c, titulo, 14, 12, Ui.OURO, 11, 0, 1.0, Ui.tit(), 3)
	var ouro := str(int(Save.d.ouro))
	Ui.txt(c, ouro, W - 14, 12, Ui.OURO, 9, 2, 1.0, Ui.neg())
	var pm := Vector2(W - 20 - Ui.largura(ouro, 9, Ui.neg()), 12)
	Ui.losango(c, pm, 4.2, Ui.TINTA); Ui.losango(c, pm, 3.3, Color("#e8b93a")); Ui.losango(c, pm + Vector2(-0.6, -0.6), 1.2, Color("#fff0a8"))

func _rodape(c: CanvasItem, itens: Array) -> void:
	var x := 14.0
	for it in itens:
		x = Ui.teclas(c, it[0], x, 261, 5)
		Ui.txt(c, it[1], x + 1, 261, Ui.APAGADO, 6)
		x += Ui.largura(it[1], 6) + 10

func _d_lobby(apagado := false) -> void:
	var c := frente
	var W := GameData.W
	_topo(c, "LIGA DOS GUERREIROS")
	var d: Dictionary = GameData.CLASSES[heroi]
	var s := Save.pers(d.id)
	if not apagado:
		for i in LOBBY.size():
			var ent := clampf((tt - i * 3) / 10.0, 0, 1)
			var r := Rect2(22 - (1.0 - ent) * 30, 44 + i * 23 + (8 if i >= 4 else 0), 150, 19)
			Ui.botao(c, r, LOBBY[i][0], i == sel, LOBBY[i][1] == "", t)
		# placa do herói
		var px := 412.0
		Ui.txt(c, d.name.to_upper(), px, 150, Color.WHITE, 20, 1, 1.0, Ui.tit(), 3)
		Ui.txt(c, d.cls, px, 166, d.trim, 9, 1, 1.0, Ui.tit())
		Ui.filete(c, px - 45, 176, 90)
		Ui.txt(c, "Nível %d" % int(s.nivel), px, 187, Ui.CLARO, 8, 1, 1.0, Ui.neg())
		Ui.barra(c, Rect2(px - 40, 195, 80, 3.5), float(s.xp) / Save.xp_para(int(s.nivel)), Color("#ffe08a"), Color("#b8862c"))
		Ui.txt(c, "%d / %d de experiência" % [int(s.xp), Save.xp_para(int(s.nivel))], px, 205, Ui.APAGADO, 5, 1)
		Ui.txt(c, d.weapon, px, 216, Ui.APAGADO, 6, 1)
		_rodape(c, [[["cima", "baixo"], "escolher"], [["Z"], "confirmar"], [["C"], "voltar"]])

func _d_herois() -> void:
	var c := frente
	var W := GameData.W
	_topo(c, "PERSONAGENS")
	var todos := GameData.CLASSES.size() + GameData.FUTUROS.size()
	for i in todos:
		var r := Rect2(40 + i * 104, 26, 96, 118)
		if i < GameData.CLASSES.size():
			var k: Dictionary = GameData.CLASSES[i]
			Ui.txt(c, k.name, r.get_center().x, r.end.y - 17, Color.WHITE, 10, 1, 1.0, Ui.tit())
			Ui.txt(c, k.cls, r.get_center().x, r.end.y - 7, k.trim, 6, 1)
			Ui.txt(c, "Nv %d" % Save.nivel(k.id), r.end.x - 5, r.position.y + 8, Ui.OURO, 6, 2, 1.0, Ui.neg())
		else:
			var f: Dictionary = GameData.FUTUROS[i - GameData.CLASSES.size()]
			Ui.txt(c, "?", r.get_center().x, r.get_center().y - 8, Ui.APAGADO.darkened(0.3), 46, 1, 1.0, Ui.deco())
			Ui.txt(c, f.name, r.get_center().x, r.end.y - 16, Ui.APAGADO, 10, 1, 1.0, Ui.tit())
			Ui.txt(c, "%s · em breve" % f.cls, r.get_center().x, r.end.y - 6, Ui.APAGADO.darkened(0.2), 6, 1)
	var d: Dictionary = GameData.CLASSES[heroi]
	var p := Rect2(40, 150, 400, 102)
	Ui.painel(c, p, 0.94)
	Ui.txt(c, d.name.to_upper(), p.position.x + 12, p.position.y + 14, Color.WHITE, 14, 0, 1.0, Ui.tit(), 3)
	Ui.txt(c, "%s  ·  %s" % [d.cls, d.weapon], p.position.x + 14 + Ui.largura(d.name.to_upper(), 14, Ui.tit()), p.position.y + 15, d.trim, 7)
	Ui.txt(c, d.role, p.position.x + 12, p.position.y + 27, Ui.OURO, 6)
	Ui.txt(c, d.desc[0], p.position.x + 12, p.position.y + 38, Ui.CLARO, 6)
	Ui.txt(c, d.desc[1], p.position.x + 12, p.position.y + 46, Ui.CLARO, 6)
	var i := 0
	for nome in d.stats:
		var y := p.position.y + 58 + i * 10.0
		Ui.txt(c, nome, p.position.x + 12, y, Ui.APAGADO, 6)
		for n in 5:
			var q := Vector2(p.position.x + 52 + n * 9, y)
			Ui.losango(c, q, 3.4, Ui.TINTA); Ui.losango(c, q, 2.6, Color(d.trim) if n < int(d.stats[nome]) else Color("#2c2740"))
		i += 1
	Ui.txt(c, "HABILIDADES", p.position.x + 190, p.position.y + 14, Ui.OURO, 7, 0, 1.0, Ui.tit())
	var nivel := Save.nivel(d.id)
	for k in 3:
		var sk: Dictionary = d.skills[k]
		var y := p.position.y + 33 + k * 24.0
		var r := Rect2(p.position.x + 190, y - 10, 20, 20)
		Ui.grad(c, r, Color("#241a40"), Color("#0c0918")); c.draw_rect(r, Ui.OURO_ESC, false, 0.6)
		Ui.icone(c, sk.ico, r.get_center(), 14, Color(sk.c), nivel > k)
		Ui.txt(c, sk.n, r.end.x + 6, y - 4, Color.WHITE if nivel > k else Ui.APAGADO, 7, 0, 1.0, Ui.neg())
		Ui.txt(c, sk.d if nivel > k else "Libera no nível %d" % (k + 1), r.end.x + 6, y + 5, Ui.CLARO.darkened(0.15) if nivel > k else Ui.APAGADO, 5)
		Ui.txt(c, "carga %d" % (k + 1), p.end.x - 10, y - 4, "#7cc4ff", 5, 2)
	_rodape(c, [[["esq", "dir"], "escolher"], [["Z"], "confirmar"]])

func _d_fases() -> void:
	var c := frente
	var W := GameData.W
	_topo(c, "ESCOLHA A FASE")
	var mapa := Rect2(24, 30, 432, 132)
	Ui.painel(c, mapa, 0.9)
	Ui.grad(c, mapa.grow(-2), Color(0.16, 0.11, 0.3, 0.6), Color(0.05, 0.03, 0.1, 0.6))
	Ui.txt(c, "REINO CAÍDO DE ARVÁLIA", mapa.get_center().x, mapa.position.y + 11, Ui.cor(Ui.OURO, 0.8), 7, 1, 1.0, Ui.tit())
	# colinas e silhuetas do mapa
	for i in 9:
		var mx := mapa.position.x + 20 + i * 48.0
		var my := mapa.end.y - 6.0
		var alt := 14.0 + (i * 37 % 23)
		c.draw_colored_polygon(PackedVector2Array([Vector2(mx - 30, my), Vector2(mx, my - alt), Vector2(mx + 30, my)]), Color(0.1, 0.07, 0.2, 0.7))
	var fs := GameData.FASES
	for i in fs.size() - 1:
		var a := Vector2(fs[i].x, fs[i].y - 40)
		var b := Vector2(fs[i + 1].x, fs[i + 1].y - 40)
		var aberto: bool = fs[i + 1].pronta
		var n := 12
		for k in n:
			if k % 2 == 0:
				var p0 := a.lerp(b, k / float(n)) + Vector2(0, sin(k / float(n) * PI) * -8)
				var p1 := a.lerp(b, (k + 1) / float(n)) + Vector2(0, sin((k + 1) / float(n) * PI) * -8)
				c.draw_line(p0, p1, Ui.cor(Ui.OURO if aberto else Ui.APAGADO, 0.8 if aberto else 0.35), 1.2)
	for i in fs.size():
		var f: Dictionary = fs[i]
		var p := Vector2(f.x, f.y - 40)
		var on := i == fase
		var r := 8.0 if on else 6.0
		if on: Ui.losango(c, p, r + 4 + sin(t * 0.1) * 1.2, Ui.cor(Ui.OURO, 0.35))
		Ui.losango(c, p, r + 1.5, Ui.TINTA)
		Ui.losango(c, p, r, Ui.OURO if f.pronta else Color("#4a4460"))
		Ui.losango(c, p, r - 2.2, Color("#7a2a3a") if f.pronta else Color("#221d33"))
		Ui.txt(c, str(i + 1), p.x, p.y - 0.3, Color.WHITE if f.pronta else Ui.APAGADO, 7, 1, 1.0, Ui.neg(), 1)
		Ui.txt(c, f.n, p.x, p.y + 16, Color.WHITE if on else (Ui.CLARO if f.pronta else Ui.APAGADO), 6, 1, 1.0, Ui.tit())
		var feito = Save.feito(f.id, 0)
		if feito != null:
			Ui.txt(c, feito.rank, p.x + 11, p.y - 9, Ui.OURO, 9, 1, 1.0, Ui.deco())
	var f: Dictionary = fs[fase]
	var inf := Rect2(24, 168, 432, 82)
	Ui.painel(c, inf, 0.94)
	Ui.txt(c, f.n.to_upper(), inf.position.x + 12, inf.position.y + 14, Color.WHITE, 13, 0, 1.0, Ui.tit(), 3)
	Ui.txt(c, f.sub, inf.position.x + 12, inf.position.y + 28, Ui.CLARO, 7)
	if f.pronta:
		Ui.txt(c, "Chefe: %s" % f.chefe, inf.position.x + 12, inf.position.y + 41, "#ffb38a", 7)
		for d in GameData.DIFS.size():
			var D: Dictionary = GameData.DIFS[d]
			var r := Rect2(inf.position.x + 250, inf.position.y + 8 + d * 23, 172, 20)
			var lib := liberada(d)
			var on := d == dif
			Ui.grad_h(c, r, Color("#5a3f9a", 0.9) if on else Color("#151026", 0.8), Color("#2a1d52", 0.2))
			if on: c.draw_rect(r, Ui.OURO, false, 0.7)
			Ui.txt(c, D.n, r.position.x + 8, r.get_center().y, Color(D.c) if lib else Ui.APAGADO.darkened(0.3), 8, 0, 1.0, Ui.tit())
			var feito = Save.feito(f.id, d)
			if not lib:
				Ui.txt(c, "vença o anterior", r.end.x - 6, r.get_center().y, Ui.APAGADO.darkened(0.2), 5, 2)
			elif feito != null:
				Ui.txt(c, "Rank %s  ·  %d:%02d" % [feito.rank, int(feito.tempo) / 60, int(feito.tempo) % 60], r.end.x - 6, r.get_center().y, Ui.OURO, 6, 2, 1.0, Ui.neg())
			else:
				Ui.txt(c, "prêmio x%.1f" % D.premio, r.end.x - 6, r.get_center().y, Ui.CLARO.darkened(0.2), 6, 2)
		var hd: Dictionary = GameData.CLASSES[heroi]
		Ui.txt(c, "Herói: %s, nível %d" % [hd.name, Save.nivel(hd.id)], inf.position.x + 12, inf.position.y + 56, Ui.APAGADO, 6)
		if t % 60 < 42 and liberada(dif):
			var x := Ui.teclas(c, ["Z"], inf.position.x + 12, inf.position.y + 70, 6)
			Ui.txt(c, "entrar na fase", x + 1, inf.position.y + 70, Color.WHITE, 7)
	else:
		Ui.txt(c, "Em construção. Esta fase chega numa próxima versão.", inf.position.x + 12, inf.position.y + 44, Ui.OURO, 7)
	_rodape(c, [[["esq", "dir"], "fase"], [["cima", "baixo"], "dificuldade"], [["Z"], "entrar"], [["C"], "voltar"]])

func _d_opcoes() -> void:
	var c := frente
	var p := Rect2(60, 60, 220, 150)
	Ui.painel(c, p, 0.95, true)
	Ui.titulo(c, "OPÇÕES", p.get_center().x, p.position.y + 16, Ui.OURO, 13)
	Ui.filete(c, p.position.x + 40, p.position.y + 28, 140)
	for i in Save.OPCOES.size():
		var r := Rect2(p.position.x + 16, p.position.y + 40 + i * 23, 188, 19)
		Ui.botao(c, r, Save.OPCOES[i][1], i == op_sel, false, t)
		Ui.txt(c, Save.texto_op(Save.OPCOES[i][0]), r.end.x - 20, r.get_center().y, Ui.OURO if i == op_sel else Ui.CLARO, 8, 1, 1.0, Ui.neg())
		if i == op_sel:
			Ui.seta(c, Vector2(r.end.x - 40, r.get_center().y), Vector2.LEFT, 2.8, Ui.OURO)
			Ui.seta(c, Vector2(r.end.x, r.get_center().y), Vector2.RIGHT, 2.8, Ui.OURO)
	_rodape(c, [[["cima", "baixo"], "escolher"], [["esq", "dir"], "ajustar"], [["C"], "voltar"]])

func _d_golpes() -> void:
	var c := frente
	var p := Rect2(40, 34, 300, 208)
	Ui.painel(c, p, 0.95, true)
	Ui.titulo(c, "GOLPES", p.get_center().x, p.position.y + 15, Ui.OURO, 13)
	Ui.filete(c, p.position.x + 70, p.position.y + 27, 160)
	Ui.ajuda(c, p.position.x + 14, p.position.y + 40, 12.4, 6)
	var d: Dictionary = GameData.CLASSES[heroi]
	Ui.txt(c, "HABILIDADES DE %s" % d.name.to_upper(), p.position.x + 14, p.position.y + 168, Ui.OURO, 7, 0, 1.0, Ui.tit())
	for k in 3:
		var sk: Dictionary = d.skills[k]
		var x := p.position.x + 14 + k * 94.0
		Ui.icone(c, sk.ico, Vector2(x + 7, p.position.y + 186), 13, Color(sk.c))
		Ui.txt(c, sk.n, x + 17, p.position.y + 183, Color.WHITE, 6, 0, 1.0, Ui.neg())
		Ui.txt(c, "carga nível %d" % (k + 1), x + 17, p.position.y + 191, "#7cc4ff", 5)
	_rodape(c, [[["C"], "voltar"]])
