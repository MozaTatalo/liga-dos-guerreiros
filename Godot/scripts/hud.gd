extends Node2D
## Interface da fase: painel do herói, mana em 3 níveis, habilidades, combo, chefe, pausa e telas de fim.

var game
var combo_pulo := 0.0
var combo_ant := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _draw() -> void:
	var W := GameData.W
	var H := GameData.H
	for i in game.players.size():
		_painel(game.players[i], 6 + i * 170.0)
	_habilidades(game.players[0])
	_topo_direita()
	_combo()
	var chefe: Enemy = null
	for e in game.enemies:
		if e.boss: chefe = e
	if chefe: _chefe(chefe)
	else: _progresso()
	if game.msg_t > 0 and game.result == null:
		var a := minf(1.0, game.msg_t / 20.0)
		Ui.filete(self, W / 2 - 110, 62, 220, a * 0.8)
		Ui.titulo(self, game.msg, W / 2, 74, "#fff3c4", 13, 1, a)
		Ui.filete(self, W / 2 - 110, 86, 220, a * 0.8)
	if not game.faixa.is_empty(): _faixa()
	if game.t < 720 and game.result == null and not game.paused: _dicas()
	if game.paused: _pausa()
	if game.alive_players().is_empty() and game.all_dead_t > 40: _derrota()
	if game.result != null: _resultado()

# ---------------- Painel do herói ----------------
func _painel(p: Hero, px: float) -> void:
	var d := p.d
	var tr := Color(d.trim)
	# faixa de fundo que some para a direita
	Ui.grad_h(self, Rect2(px + 14, 9, 150, 28), Color(0.04, 0.03, 0.08, 0.82), Color(0.04, 0.03, 0.08, 0.0))
	# retrato num losango com moldura dourada
	var c := Vector2(px + 19, 23)
	Ui.losango(self, c, 20.5, Ui.TINTA); Ui.losango(self, c, 19.2, Ui.OURO); Ui.losango(self, c, 17.6, Color("#1c1532"))
	if p.view and p.view.vp:
		# recorte da cabeça do próprio boneco 3D (ao vivo, até pisca), dentro do losango
		var uv0 := Vector2(136, 86) / 384.0
		var uv1 := Vector2(237, 194) / 384.0
		var pts := PackedVector2Array([c + Vector2(0, -17), c + Vector2(17, 0), c + Vector2(0, 17), c + Vector2(-17, 0)])
		var uvs := PackedVector2Array()
		for q in pts:
			var k := (q - (c - Vector2(15, 16))) / Vector2(30, 32)
			uvs.append(uv0 + (uv1 - uv0) * k)
		draw_polygon(pts, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), uvs, p.view.vp.get_texture())
	# nível
	var nb := c + Vector2(0, 18)
	Ui.losango(self, nb, 6.2, Ui.TINTA); Ui.losango(self, nb, 5.2, tr.darkened(0.25))
	Ui.txt(self, str(p.lvl), nb.x, nb.y - 0.3, Color.WHITE, 6, 1, 1.0, Ui.neg(), 1)
	var bx := px + 43
	Ui.txt(self, d.name, bx, 12, Color.WHITE, 8, 0, 1.0, Ui.tit())
	Ui.txt(self, d.cls, bx + Ui.largura(d.name, 8, Ui.tit()) + 4, 12.5, tr, 5)
	# vida
	var rv := Rect2(bx, 17.5, 112, 6.5)
	var baixa: bool = p.hp < p.maxhp * 0.25 and not p.dead
	var pisca: bool = baixa and game.t % 30 < 15
	Ui.barra(self, rv, p.hp / p.maxhp, Color("#ff6a5c") if pisca else Color("#e8483f"), Color("#8f1d26"), p.hp_rastro / p.maxhp)
	Ui.txt(self, "%d / %d" % [ceili(p.hp), int(p.maxhp)], rv.get_center().x, rv.get_center().y, Color.WHITE, 5, 1, 1.0, Ui.neg(), 1)
	# mana em 3 níveis
	var mw := 30.0
	for i in 3:
		var r := Rect2(bx + i * (mw + 2.5), 27, mw, 4.5)
		var k := clampf(p.mp - i, 0.0, 1.0)
		var liberado := i < p.niveis()
		var cheio := k >= 1.0
		var ca := Color("#7cc4ff") if cheio else Color("#3d6fd6")
		Ui.barra(self, r, k, ca, Color("#1f3d99") if liberado else Color("#33364a"), -1.0, Color("#0a1030"))
		if cheio and liberado:
			draw_rect(r, Color(0.7, 0.9, 1.0, 0.18 + 0.12 * sin(game.t * 0.12 + i)))
		if p.state == "charge":
			var kc := clampf(p.charge - i, 0.0, 1.0)
			if kc > 0:
				var cs := Color(d.skills[i].c)
				draw_rect(Rect2(r.position, Vector2(r.size.x * kc, r.size.y)), Color(cs.r, cs.g, cs.b, 0.95))
				draw_rect(Rect2(r.position, Vector2(r.size.x * kc, 1.3)), Color(1, 1, 1, 0.7))
		if not liberado:
			Ui.txt(self, "nível %d" % (i + 1), r.get_center().x, r.get_center().y, Ui.APAGADO, 4, 1, 1.0, null, 1)
	# experiência
	var rx := Rect2(bx, 34, 95, 1.6)
	draw_rect(rx, Color(0, 0, 0, 0.7))
	draw_rect(Rect2(rx.position, Vector2(rx.size.x * clampf(float(p.xp) / Save.xp_para(p.lvl), 0, 1), rx.size.y)), Ui.OURO)
	if p.deny_t > 0:
		Ui.txt(self, "Mana insuficiente", bx, 41, "#ff8a8a", 6, 0, minf(1.0, p.deny_t / 10.0))

# ---------------- Habilidades (níveis de carga) ----------------
func _habilidades(p: Hero) -> void:
	var H := GameData.H
	var y := H - 30.0
	for i in 3:
		var x := 10.0 + i * 27.0
		var sk: Dictionary = p.d.skills[i]
		var liberado := i < p.niveis()
		var pronto := liberado and p.mp >= i + 1
		var carregando: bool = p.state == "charge" and p.charge_lv == i + 1
		var usando: bool = p.state == "skill" and p.skill == i
		var r := Rect2(x, y, 22, 22)
		if carregando or usando: r = r.grow(1.5)
		Ui.grad(self, r, Color("#241a40", 0.92), Color("#0c0918", 0.92))
		var cs := Color(sk.c)
		if pronto: draw_rect(r.grow(-1.5), Color(cs.r, cs.g, cs.b, 0.16))
		Ui.icone(self, sk.ico, r.get_center(), 15.0 if liberado else 12.0, cs, pronto or carregando or usando)
		draw_rect(r, (Color.WHITE if (carregando or usando) else (Ui.OURO if pronto else Ui.OURO_ESC.darkened(0.3))), false, 1.2 if (carregando or usando) else 0.7)
		# quantos níveis de mana custa
		for n in i + 1:
			Ui.losango(self, Vector2(r.get_center().x - i * 2.5 + n * 5.0, r.end.y + 0.5), 2.3, Ui.TINTA)
			Ui.losango(self, Vector2(r.get_center().x - i * 2.5 + n * 5.0, r.end.y + 0.5), 1.6, Color("#7cc4ff") if pronto else Color("#3a4468"))
		if not liberado:
			draw_rect(r, Color(0.02, 0.01, 0.05, 0.55))
			Ui.txt(self, "Nv %d" % (i + 1), r.get_center().x, r.get_center().y, Ui.CLARO, 6, 1, 1.0, Ui.neg())
	var hx := Ui.teclas(self, ["segure", "Z"], 94, H - 14, 5)
	Ui.txt(self, "carrega a habilidade", hx + 1, H - 14, Ui.APAGADO, 5)
	Ui.teclas(self, ["P"], 94, H - 23, 5)
	Ui.txt(self, "golpes e pausa", 105, H - 23, Ui.APAGADO, 5)

func _topo_direita() -> void:
	var W := GameData.W
	var seg := int(game.t / 60)
	Ui.txt(self, "%d:%02d" % [seg / 60, seg % 60], W - 8, 11, Ui.CLARO, 8, 2, 1.0, Ui.neg())
	var total: int = int(Save.d.ouro) + game.ouro
	var tw := Ui.largura(str(total), 7, Ui.neg())
	Ui.txt(self, str(total), W - 42, 11, Ui.OURO, 7, 2, 1.0, Ui.neg())
	var pm := Vector2(W - 47 - tw, 11)
	Ui.losango(self, pm, 3.4, Ui.TINTA); Ui.losango(self, pm, 2.6, Color("#e8b93a")); Ui.losango(self, pm + Vector2(-0.5, -0.5), 1.0, Color("#fff0a8"))
	if game.dif > 0:
		Ui.txt(self, game.D.n, W - 8, 21, game.D.c, 5, 2)

func _combo() -> void:
	var W := GameData.W
	if game.combo != combo_ant:
		if game.combo > combo_ant: combo_pulo = 1.0
		combo_ant = game.combo
	combo_pulo = maxf(0.0, combo_pulo - 0.12)
	if game.combo < 2: return
	var y := 46.0
	var rank := ""
	var rc := "#ffffff"
	for r in GameData.RANKS_COMBO:
		if game.combo >= r[0]:
			rank = r[1]; rc = r[2]
	var sz := 18 + int(combo_pulo * 6)
	var a := clampf(game.combo_t / 25.0, 0.0, 1.0)
	Ui.txt(self, str(game.combo), W - 36, y, rc, sz, 2, a, Ui.tit(), 3)
	Ui.txt(self, "GOLPES", W - 8, y + 3, Ui.CLARO, 6, 2, a, Ui.tit())
	var k: float = game.combo_t / 150.0
	draw_rect(Rect2(W - 70, y + 11, 62, 1.6), Color(0, 0, 0, 0.6 * a))
	draw_rect(Rect2(W - 8 - 62 * k, y + 11, 62 * k, 1.6), Ui.cor(rc, a))
	if rank != "":
		Ui.txt(self, rank, W - 8, y + 19, rc, 9, 2, a, Ui.tit())

func _progresso() -> void:
	var W := GameData.W
	var lead := 0.0
	for p in game.players: lead = maxf(lead, p.x)
	var pr := clampf(lead / GameData.PORTAL_X, 0, 1)
	var x0 := W / 2 - 55
	draw_rect(Rect2(x0, 10, 110, 1.2), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(x0, 10, 110 * pr, 1.2), Ui.cor(Ui.OURO, 0.9))
	for m in [1100.0, GameData.ARENA_L]:
		Ui.losango(self, Vector2(x0 + 110 * m / GameData.PORTAL_X, 10.6), 1.8, Ui.OURO_ESC)
	Ui.losango(self, Vector2(x0 + 110, 10.6), 2.6, Color("#59d0ff"))
	Ui.losango(self, Vector2(x0 + 110 * pr, 10.6), 3.0, Ui.TINTA); Ui.losango(self, Vector2(x0 + 110 * pr, 10.6), 2.2, Color.WHITE)

func _chefe(e: Enemy) -> void:
	var W := GameData.W
	var bw := 222.0
	var bx := 178.0
	var by := 26.0
	var camadas := 3
	var por: float = e.maxhp / camadas
	var atual := clampi(int(ceil(e.hp / por)), 1, camadas)
	var k: float = (e.hp - (atual - 1) * por) / por
	var cores := [[Color("#e8483f"), Color("#8f1d26")], [Color("#f08a3c"), Color("#9a4a16")], [Color("#b56cff"), Color("#5a2a9a")]]
	var fundo: Color = cores[atual - 2][1].darkened(0.35) if atual > 1 else Color("#120a14")
	Ui.barra(self, Rect2(bx, by, bw, 6), k, cores[atual - 1][0], cores[atual - 1][1], -1.0, fundo)
	Ui.txt(self, GameData.ENEMIES[e.kind].nome.to_upper(), bx, by - 6, "#ffcf8a", 7, 0, 1.0, Ui.tit())
	Ui.txt(self, "x%d" % atual, bx + bw, by - 6, Color.WHITE, 7, 2, 1.0, Ui.neg())
	Ui.losango(self, Vector2(bx - 5, by + 3), 4.2, Ui.TINTA); Ui.losango(self, Vector2(bx - 5, by + 3), 3.2, Ui.SANGUE)

## Faixa com o nome da habilidade suprema, atravessando a tela.
func _faixa() -> void:
	var W := GameData.W
	var f: Dictionary = game.faixa
	var t: float = f.t
	var a := clampf(t / 6.0, 0, 1) * clampf((70 - t) / 12.0, 0, 1)
	var y := 96.0
	var c := Color(f.c)
	Ui.grad_h(self, Rect2(0, y - 13, W, 26), Color(0.02, 0.01, 0.06, 0.85 * a), Color(0.02, 0.01, 0.06, 0.2 * a))
	draw_rect(Rect2(0, y - 13, W, 0.8), Ui.cor(c, a)); draw_rect(Rect2(0, y + 12.2, W, 0.8), Ui.cor(c, a))
	var x := 60.0 + (1.0 - pow(1.0 - clampf(t / 14.0, 0, 1), 3.0)) * 40.0 + t * 0.4
	Ui.txt(self, f.n.to_upper(), x, y + 1, Color.WHITE, 17, 0, a, Ui.tit(), 3)
	Ui.txt(self, "Habilidade suprema de %s" % f.heroi, x + 1, y - 9, c, 5, 0, a)

# ---------------- Pausa ----------------
func _pausa() -> void:
	var W := GameData.W
	var H := GameData.H
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.01, 0.05, 0.72))
	Ui.painel(self, Rect2(40, 44, 150, 182), 0.95)
	Ui.titulo(self, "PAUSA", 115, 60, Ui.OURO, 13)
	Ui.filete(self, 60, 72, 110)
	for i in game.PAUSA.size():
		var item: String = game.PAUSA[i]
		var r := Rect2(54, 82 + i * 21, 124, 17)
		var rot := item
		var valor := ""
		for o in Save.OPCOES:
			if o[0] == item:
				rot = o[1]; valor = Save.texto_op(item)
		Ui.botao(self, r, rot, i == game.pausa_sel, false, Engine.get_physics_frames())
		if valor != "":
			Ui.txt(self, valor, r.end.x - 14, r.get_center().y, Ui.OURO if i == game.pausa_sel else Ui.CLARO, 7, 1, 1.0, Ui.neg())
			if i == game.pausa_sel:
				Ui.seta(self, Vector2(r.end.x - 30, r.get_center().y), Vector2.LEFT, 2.5, Ui.OURO)
				Ui.seta(self, Vector2(r.end.x + 2, r.get_center().y), Vector2.RIGHT, 2.5, Ui.OURO)
	Ui.painel(self, Rect2(200, 44, 240, 182), 0.95)
	Ui.titulo(self, "GOLPES", 320, 60, Ui.OURO, 13)
	Ui.filete(self, 250, 72, 140)
	Ui.ajuda(self, 212, 86, 12.6, 6)
	Ui.txt(self, "Setas: escolher e ajustar   ·   Z: confirmar   ·   P: voltar ao jogo", W / 2, H - 14, Ui.APAGADO, 6, 1)

func _derrota() -> void:
	var W := GameData.W
	var H := GameData.H
	var a := clampf((game.all_dead_t - 40) / 40.0, 0, 1)
	draw_rect(Rect2(0, 0, W, H), Color(0.12, 0.0, 0.02, 0.6 * a))
	Ui.filete(self, W / 2 - 120, H / 2 - 30, 240, a)
	Ui.titulo(self, "VOCÊ CAIU", W / 2, H / 2 - 12, "#ff8080", 24, 1, a)
	Ui.txt(self, "A experiência e o ouro que você juntou foram guardados.", W / 2, H / 2 + 8, Ui.CLARO, 7, 1, a)
	Ui.filete(self, W / 2 - 120, H / 2 + 20, 240, a)
	if game.all_dead_t > 60:
		var x := Ui.teclas(self, ["R"], W / 2 - 78, H / 2 + 36, 6)
		Ui.txt(self, "tentar de novo", x + 1, H / 2 + 36, Color.WHITE, 7)
		x = Ui.teclas(self, ["Z"], W / 2 + 12, H / 2 + 36, 6)
		Ui.txt(self, "voltar ao lobby", x + 1, H / 2 + 36, Color.WHITE, 7)

# ---------------- Resultado ----------------
func _resultado() -> void:
	var W := GameData.W
	var H := GameData.H
	var r: Dictionary = game.result
	var t: float = game.result_t
	var a := clampf(t / 20.0, 0, 1)
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.01, 0.05, 0.6 * a))
	var pr := Rect2(W / 2 - 150, 34, 300, 204)
	Ui.painel(self, pr, 0.95 * a, true)
	Ui.titulo(self, "FASE CONCLUÍDA", W / 2, 52, Ui.OURO, 16, 1, a)
	Ui.txt(self, "%s  ·  %s" % [game.fase.n, game.D.n], W / 2, 66, Ui.CLARO, 7, 1, a)
	Ui.filete(self, W / 2 - 100, 75, 200, a)
	var linhas := [["Tempo", "%d:%02d" % [int(r.time) / 60, int(r.time) % 60]], ["Maior combo", str(game.max_combo)],
		["Dano recebido", str(r.dt)], ["Inimigos derrotados", str(game.kills)]]
	for i in linhas.size():
		var la := clampf((t - 15 - i * 8) / 10.0, 0, 1)
		var y := 90.0 + i * 14
		Ui.txt(self, linhas[i][0], pr.position.x + 22, y, Ui.CLARO, 8, 0, la)
		Ui.txt(self, linhas[i][1], pr.position.x + 170, y, Color.WHITE, 8, 2, la, Ui.neg())
	# emblema do rank
	var ra := clampf((t - 50) / 8.0, 0, 1)
	if ra > 0:
		var rc := Color({"S": "#ffd23f", "A": "#8fe388", "B": "#7db8ff", "C": "#cfd3e6"}[r.rank])
		var c := Vector2(pr.end.x - 62, 110)
		var esc := 1.0 + (1.0 - ra) * 1.2
		Ui.losango(self, c, 36 * esc, Ui.cor(Ui.TINTA, ra)); Ui.losango(self, c, 34 * esc, Ui.cor(rc, ra * 0.9)); Ui.losango(self, c, 31 * esc, Ui.cor("#1c1532", ra))
		Ui.txt(self, r.rank, c.x, c.y + 1, rc, int(40 * esc), 1, ra, Ui.deco(), 3)
		Ui.txt(self, "RANK", c.x, c.y - 42, Ui.CLARO, 7, 1, ra, Ui.tit())
		if r.recorde: Ui.txt(self, "Novo recorde!", c.x, c.y + 44, Ui.OURO, 7, 1, ra * (0.6 + 0.4 * sin(t * 0.2)))
	# recompensas
	Ui.filete(self, W / 2 - 100, 152, 200, a)
	var ka := clampf((t - 60) / 60.0, 0, 1)
	var ke := 1.0 - pow(1.0 - ka, 2.0)
	Ui.txt(self, "Ouro", pr.position.x + 22, 166, Ui.CLARO, 8, 0, a)
	Ui.txt(self, "+%d" % int(r.ouro * ke), pr.position.x + 170, 166, Ui.OURO, 9, 2, a, Ui.neg())
	Ui.txt(self, "Experiência", pr.position.x + 22, 180, Ui.CLARO, 8, 0, a)
	Ui.txt(self, "+%d" % int(r.xp * ke), pr.position.x + 170, 180, "#9fd3ff", 9, 2, a, Ui.neg())
	var p: Hero = game.players[0]
	var antes: float = r.antes[0][0] + float(r.antes[0][1]) / Save.xp_para(r.antes[0][0])
	var depois: float = p.lvl + float(p.xp) / Save.xp_para(p.lvl)
	# a experiência ganha durante a fase já está no herói; a barra anima do começo da fase até agora
	var ini: float = minf(antes, depois)
	var atual: float = lerpf(ini, depois, ke)
	var nv := int(atual)
	Ui.txt(self, "%s  ·  Nível %d" % [p.d.name, nv], pr.position.x + 22, 197, Color.WHITE, 8, 0, a, Ui.tit())
	Ui.barra(self, Rect2(pr.position.x + 22, 205, 256, 5), atual - nv, Color("#ffe08a"), Color("#b8862c"))
	if nv > int(ini): Ui.txt(self, "SUBIU DE NÍVEL!", pr.end.x - 22, 197, Ui.OURO, 8, 2, a, Ui.tit())
	if t > 50:
		var x := Ui.teclas(self, ["Z"], W / 2 - 92, 225, 6)
		Ui.txt(self, "voltar ao lobby", x + 1, 225, Color.WHITE, 7)
		x = Ui.teclas(self, ["R"], W / 2 + 24, 225, 6)
		Ui.txt(self, "jogar de novo", x + 1, 225, Color.WHITE, 7)

## Lembrete dos comandos no começo da fase.
func _dicas() -> void:
	var a := clampf(game.t / 30.0, 0, 1) * clampf((720 - game.t) / 40.0, 0, 1)
	var y := GameData.H - 44.0
	var itens := [[["Z"], "atacar"], [["baixo", "Z"], "lançar"], [["X"], "pular"], [["C"], "esquiva"], [["dir", "dir"], "correr"], [["segure", "Z"], "habilidade"]]
	var total := 0.0
	for it in itens:
		total += it[0].size() * 10.0 + Ui.largura(it[1], 6) + 12.0
	var x := GameData.W / 2 - total / 2 + 30
	modulate.a = 1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Ui.grad_h(self, Rect2(x - 12, y - 8, total, 16), Color(0.03, 0.02, 0.07, 0.75 * a), Color(0.03, 0.02, 0.07, 0.35 * a))
	if a < 0.99: return
	for it in itens:
		x = Ui.teclas(self, it[0], x, y, 6)
		Ui.txt(self, it[1], x + 1, y, Ui.CLARO, 6)
		x += Ui.largura(it[1], 6) + 10
