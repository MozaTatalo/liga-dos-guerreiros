extends Node2D
## Uma partida (fase). Gerencia jogadores, inimigos, golpes, projéteis, câmera, recompensas e regras da fase.

signal finished(acao: String)   # "lobby" ou "repetir"

const WorldScript := preload("res://scripts/world.gd")
const FxScript := preload("res://scripts/fx_layer.gd")
const HudScript := preload("res://scripts/hud.gd")
const PAUSA := ["Continuar", "musica", "efeitos", "tremor", "Reiniciar fase", "Voltar ao lobby"]

var class_indexes: Array = []
var players: Array = []      # Lista de Hero. Hoje 1; a estrutura aceita vários.
var enemies: Array = []
var hitboxes: Array = []
var projs: Array = []
var parts: Array = []
var nums: Array = []
var fx: Array = []
var timers: Array = []
var pickups: Array = []

var fase: Dictionary
var dif := 0
var D: Dictionary            # dados da dificuldade
var t := 0
var cam_x := 0.0
var combo := 0
var combo_t := 0
var max_combo := 0
var dmg_taken := 0
var kills := 0
var ouro := 0                # ouro juntado nesta partida (ainda não guardado)
var xp_ganho := 0
var msg := ""
var msg_t := 0
var boss_started := false
var boss_dead := false
var cleared := [false, false]
var result = null
var result_t := 0
var hitstop := 0
var shake := 0.0
var paused := false
var pausa_sel := 0
var all_dead_t := 0
var dim_t := 0               # tela escurecida durante a habilidade suprema
var corte := {}              # corte de cena da Fúria (retrato do herói atravessando a tela)
var intro_t := 0             # apresentação do chefe: jogo em espera, faixas de cinema
var avisos: Array = []       # áreas vermelhas no chão que avisam onde um golpe vai cair
var faixa := {}              # faixa com o nome da habilidade suprema

var bg
var world
var fx_layer
var hud
var ent_layer: Node2D
var camera: Camera2D

## class_indexes: uma classe por jogador, ex.: [0] (solo) ou [0, 2] (dois jogadores)
func setup(indexes: Array, background, fase_idx := 0, dificuldade := 0) -> void:
	class_indexes = indexes
	bg = background
	fase = GameData.FASES[fase_idx]
	dif = dificuldade
	D = GameData.DIFS[dif]
	world = WorldScript.new(); world.game = self; add_child(world)
	ent_layer = Node2D.new(); add_child(ent_layer)
	fx_layer = FxScript.new(); fx_layer.game = self; add_child(fx_layer)
	camera = Camera2D.new(); add_child(camera); camera.make_current()
	var hl := CanvasLayer.new(); hl.layer = 2; add_child(hl)
	hud = HudScript.new(); hud.game = self; hl.add_child(hud)
	for i in indexes.size():
		var p := Hero.new()
		p.setup(self, GameData.CLASSES[indexes[i]], PlayerInput.new("p%d_" % (i + 1)), i)
		ent_layer.add_child(p)
		players.append(p)
	for i in GameData.SPAWNS.size():
		for s in GameData.SPAWNS[i]:
			add_enemy(s[0], s[1], i, s[2] if s.size() > 2 else null)
	show_msg(fase.n, 170)
	Som.tema("fase")

# ---------------- Utilidades ----------------
func overlap(a, b) -> bool:
	return a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y

func alive_players() -> Array:
	return players.filter(func(p): return not p.dead)

func nearest_player(px: float) -> Hero:
	var best: Hero = null
	for p in players:
		if p.dead:
			continue
		if best == null or absf(p.cx() - px) < absf(best.cx() - px):
			best = p
	return best

func show_msg(m: String, dur := 120) -> void:
	msg = m; msg_t = dur

func add_enemy(kind: String, px: float, sec: int, plat_y = null) -> Enemy:
	var e := Enemy.new()
	e.setup(self, kind, px, sec, plat_y)
	ent_layer.add_child(e)
	if e.boss:
		ent_layer.move_child(e, 0)
	enemies.append(e)
	return e

func sec_cleared(i: int) -> bool:
	for e in enemies:
		if e.sec == i and not e.boss and e.hp > 0:
			return false
	return true

func barriers() -> Array:
	var b := []
	if not sec_cleared(0): b.append(1100.0)
	if not sec_cleared(1) or (boss_started and not boss_dead): b.append(GameData.ARENA_L)
	if not boss_dead: b.append(GameData.ARENA_R)
	return b

func apply_barriers(e) -> void:
	for bx in barriers():
		if e.x + e.w / 2 < bx:
			if e.x + e.w > bx:
				e.x = bx - e.w
				if e.vx > 0: e.vx = 0.0
		elif e.x < bx:
			e.x = bx
			if e.vx < 0: e.vx = 0.0
	e.x = clampf(e.x, 0, GameData.LEVEL_W - e.w)

func physics(e, grav := true) -> void:
	if grav:
		e.vy = minf(e.vy + 0.3, 8.5)
	e.x += e.vx
	e.y += e.vy
	e.on_ground = false
	if e.vy >= 0:
		var feet: float = e.y + e.h
		var prev: float = feet - e.vy
		if feet >= GameData.GROUND:
			e.y = GameData.GROUND - e.h; e.vy = 0.0; e.on_ground = true
		elif e.drop_t <= 0:
			for p in GameData.PLATS:
				if e.x + e.w > p.x and e.x < p.x + p.w and prev <= p.y + 0.5 and feet >= p.y:
					e.y = p.y - e.h; e.vy = 0.0; e.on_ground = true
					break
	if e.drop_t > 0:
		e.drop_t -= 1

# ---------------- Combate ----------------
func spawn_hitbox(o: Dictionary) -> void:
	o.hit = {}; o.t = 0
	if o.has("place"): o.place.call(o)
	hitboxes.append(o)

func spawn_proj(o: Dictionary) -> void:
	o.hit = {}; o.t = 0
	if not o.has("grav"): o.grav = 0.0
	projs.append(o)

func add_fx(life: int, draw_fn: Callable) -> void:
	fx.append({"t": 0, "life": life, "draw": draw_fn})

func callout(px: float, py: float, text: String, c) -> void:
	add_fx(55, func(cv, k): Ui.txt(cv, text, px, py - k * 12, c, 9, 1, 1.0 if k < 0.8 else (1 - k) * 5, Ui.tit()))
	fx[fx.size() - 1]["normal"] = true

## Anel de luz que abre. `achat` < 1 deita o anel no chão.
func anel(px: float, py: float, c, r: float, achat := 1.0) -> void:
	add_fx(14, func(cv, k):
		cv.draw_set_transform(Vector2(px, py), 0.0, Vector2(1, achat))
		cv.draw_arc(Vector2.ZERO, r * (0.25 + 0.75 * (1.0 - pow(1.0 - k, 3.0))), 0, TAU, 32, Gfx.col(c, 1.0 - k), 2.5 * (1.0 - k) + 0.5)
		cv.draw_set_transform_matrix(Transform2D.IDENTITY))

## Estrela de impacto e faíscas no ponto do golpe.
func impacto(px: float, py: float, c, forte := false) -> void:
	var tam := 9.0 if forte else 6.0
	add_fx(10 if forte else 8, func(cv, k): Gfx.impacto(cv, px, py, c, k, tam))
	sparks(px, py, c, 8 if forte else 5, 3.5 if forte else 2.5)

func sparks(px: float, py: float, c, n: int, sp := 2.5) -> void:
	for i in n:
		var a := randf_range(0, TAU)
		var s := randf_range(0.5, sp)
		parts.append({"x": px, "y": py, "vx": cos(a) * s, "vy": sin(a) * s - 0.5, "life": randf_range(14, 26), "c": c, "s": randf_range(1, 2.5), "g": 0.1})

func dust(px: float, py: float, n := 4) -> void:
	for i in n:
		parts.append({"x": px + randf_range(-4, 4), "y": py, "vx": randf_range(-1, 1), "vy": randf_range(-1, -0.2), "life": randf_range(12, 22), "c": "#9a94c8", "s": 2.0, "g": 0.0})

func ghost(p: Hero, c = null) -> void:
	parts.append({"x": p.cx(), "y": p.y + 12, "vx": 0.0, "vy": 0.0 if c == null else -0.5, "life": 10.0, "c": p.d.body if c == null else c, "s": 7.0, "g": 0.0, "a": 0.35})

## Aviso no chão: uma área vermelha que enche até o golpe cair. `larg` é a largura; `dur` em passos.
func aviso(px: float, larg: float, dur: int, faixa_ := false) -> void:
	avisos.append({"x": px, "w": larg, "t": 0, "dur": dur, "faixa": faixa_})

## Corte de cena da Fúria: o tempo para, a tela escurece e o herói atravessa a tela num retrato.
func corte_furia(p: Hero, f: Dictionary) -> void:
	dim_t = 80; hitstop = maxi(hitstop, 44)
	corte = {"t": 0, "p": p, "n": f.n, "c": f.c}
	Som.tocar("chefe", 0.7, 1.6); Som.tocar("carga_nivel", 1.0, 0.5, 0.0)

func num(px: float, py: float, v, c, big := false) -> void:
	nums.append({"x": px + randf_range(-5, 5), "y": py, "v": str(v), "c": c, "big": big, "t": 0})

## Habilidade suprema (nível 3): o tempo para um instante, a tela escurece e o nome aparece numa faixa.
func suprema(p: Hero, sk: Dictionary) -> void:
	dim_t = 70; hitstop = maxi(hitstop, 18)
	faixa = {"t": 0, "n": sk.n, "c": sk.c, "heroi": p.d.name}
	anel(p.cx(), p.y + p.h / 2, sk.c, 120.0)
	anel(p.cx(), p.y + p.h / 2, "#ffffff", 60.0)
	Som.tocar("chefe", 0.6, 1.8); Som.tocar("carga_nivel", 1.0, 0.7)

func hit(target, src: Dictionary, cxv: float) -> void:
	var dir := int(src.get("dir", 0))
	if dir == 0:
		dir = 1 if target.x + target.w / 2 >= cxv else -1
	if target is Hero:
		hurt_player(target, src.dmg, dir, src.get("kbx", 2.0), src.get("kby", 2.0), src.get("de"))
	else:
		damage_enemy(target, src, dir)

func damage_enemy(e: Enemy, src: Dictionary, dir: int) -> void:
	if e.hp <= 0 or e.imune > 0:
		return
	var heavy: bool = src.get("heavy", false)
	var crit := randf() < 0.12
	var costas: bool = not e.boss and dir == e.dir and e.state != "launched" and e.state != "down"
	var v: float = src.dmg * randf_range(0.92, 1.08) * (1.5 if crit else 1.0) * (1.25 if costas else 1.0)
	if e.state == "quebrado": v *= 1.4
	if e.state == "down": v *= 0.6
	var amount := maxi(1, int(roundf(v)))
	e.hp -= amount; e.flash_t = 6; e.active = true
	var forte := heavy or crit
	var ex := e.x + e.w / 2
	var ey := e.y + e.h / 2
	impacto(ex - dir * e.w * 0.25, ey, "#fff0b8" if forte else "#bfe4ff", forte)
	e.apanhar(src, dir, heavy)
	num(ex, e.y - 4, amount, "#ffd23f" if crit else ("#ffb38a" if costas else "#ffffff"), crit)
	if costas and not crit and combo % 3 == 0: callout(ex, e.y - 14, "Pelas costas!", "#ffb38a")
	sparks(ex - dir * 4, ey, "#ffd23f" if crit else "#fff3c4", 10 if crit else 6)
	hitstop = maxi(hitstop, 6 if heavy else 3)
	if forte and tremor_ligado(): shake = maxf(shake, 4)
	Som.tocar("critico" if crit else ("acerto2" if heavy else "acerto"), 0.9)
	combo += 1; combo_t = 150; max_combo = maxi(max_combo, combo)
	for r in GameData.RANKS_COMBO:
		if combo == r[0]:
			Som.tocar("carga_nivel", 0.7, 1.3)
	var quem = src.get("src")
	if quem is Hero:
		quem.ganhar_mana((0.012 if src.get("skill", false) else 0.05) * (1.4 if heavy else 1.0))
		quem.ganhar_furia((0.005 if src.get("skill", false) else 0.013) * (1.5 if heavy else 1.0))
	if e.hp <= 0:
		kill_enemy(e)

func tremor_ligado() -> bool:
	return Save.op("tremor")

func kill_enemy(e: Enemy) -> void:
	e.hp = 0; kills += 1
	var ex := e.x + e.w / 2
	var ey := e.y + e.h / 2
	var c: String = {"lodo": "#6fd36b", "saqueador": "#7a9cff", "morcego": "#7a5ca8", "atirador": "#b88aff", "boss": "#d9a066"}[e.kind]
	sparks(ex, ey, c, 60 if e.boss else 16, 5 if e.boss else 3)
	sparks(ex, ey, "#ffffff", 30 if e.boss else 6, 3)
	Som.tocar("morte", 0.8, 0.7 if e.boss else 1.0)
	var def: Dictionary = GameData.ENEMIES[e.kind]
	var bonus := 1.0 + mini(combo, 100) * 0.004   # combo alto rende mais experiência
	var xp := int(roundf(def.xp * D.premio * bonus))
	xp_ganho += xp
	for p in alive_players(): p.ganhar_xp(xp)
	var total := int(roundf(def.ouro * D.premio))
	var qtd := clampi(total / 2, 1, 14)
	for i in qtd:
		pickups.append({"x": ex - 3, "y": ey - 4, "w": 6.0, "h": 6.0, "vx": randf_range(-1.8, 1.8), "vy": randf_range(-4.5, -2.0), "kind": "ouro",
			"v": total / qtd + (1 if i < total % qtd else 0), "t": 0})
	if e.boss:
		boss_dead = true; shake = 14.0; hitstop = 24
		show_msg("%s derrotado! Siga para o portal" % def.nome, 240)
		Som.tema(""); Som.tocar("explosao")
		for i in 6:
			timers.append({"t": i * 8, "fn": func(): sparks(ex + randf_range(-20, 20), ey + randf_range(-20, 20), "#ffb347", 20, 4)})
	elif randf() < 0.3:
		pickups.append({"x": ex - 4, "y": e.y, "w": 8.0, "h": 8.0, "vx": 0.0, "vy": -2.0, "kind": "hp" if randf() < 0.6 else "mp", "t": 0})

func hurt_player(p: Hero, dmg: float, dir: int, kbx := 2.0, kby := 2.0, de = null) -> void:
	if p.invuln > 0 or p.dead or result != null:
		return
	dmg = roundf(dmg * D.dano)
	if p.state == "guard" and dir == -p.facing:
		_defender(p, dmg, dir, de)
		return
	p.hp -= dmg; dmg_taken += int(dmg)
	num(p.cx(), p.y - 4, int(dmg), "#ff5b5b")
	sparks(p.cx(), p.y + 10, "#ff5b5b", 8)
	if tremor_ligado(): shake = maxf(shake, 5)
	hitstop = maxi(hitstop, 4); combo = 0
	p.ganhar_mana(0.08); p.ganhar_furia(0.09)
	Som.tocar("dano")
	if p.hp <= 0:
		p.hp = 0; p.dead = true; p.state = "dead"; p.vx = dir * 2; p.vy = -3
		return
	p.state = "hurt"; p.state_t = 0; p.vx = dir * kbx; p.vy = -kby; p.invuln = 60; p.skill = -1; p.mv = ""; p.charge = 0.0; p.charge_lv = 0

## Defesa do Guardião. No tempo certo (logo depois de levantar o escudo) não leva dano e abre contra-ataque.
func _defender(p: Hero, dmg: float, dir: int, de) -> void:
	var px := p.cx() + p.facing * 9.0
	var py := p.y + 10
	if p.state_t <= 10:
		p.invuln = 22; p.contra_t = 45; p.ganhar_mana(0.3); p.ganhar_furia(0.07)
		hitstop = maxi(hitstop, 9)
		callout(p.cx(), p.y - 18, "DEFESA PERFEITA!", "#ffe9a8")
		impacto(px, py, "#ffe9a8", true); anel(px, py, "#ffe9a8", 26.0)
		Som.tocar("critico", 0.9, 1.3); Som.tocar("acerto2", 0.8, 1.4)
		if de is Enemy and is_instance_valid(de) and de.hp > 0:
			if de.boss: de.perder_postura(30.0)
			else:
				de.hurt_t = 55; de.state = "walk"; de.t = 0; de.vx = dir * -2.0
	else:
		var v := maxf(1.0, roundf(dmg * 0.2))
		p.hp = maxf(1.0, p.hp - v); dmg_taken += int(v)
		num(p.cx(), p.y - 4, int(v), "#bfe4ff")
		p.vx = dir * 1.6; p.invuln = 10; p.ganhar_furia(0.03)
		impacto(px, py, "#bfe4ff"); Som.tocar("acerto", 0.8, 0.7)

func explode(px: float, py: float, w: float, h: float, dmg: float, launch: float, c: String, quem = null) -> void:
	spawn_hitbox({"owner": "p", "src": quem, "skill": true, "x": px - w / 2, "y": py - h / 2, "w": w, "h": h, "dmg": dmg, "kbx": 2.6, "launch": launch, "life": 6, "heavy": true})
	if tremor_ligado(): shake = maxf(shake, 6)
	sparks(px, py, c, 26, 4); sparks(px, py, "#fff6d0", 10, 3)
	add_fx(16, func(cv, k): cv.draw_circle(Vector2(px, py), (w / 2) * (0.4 + k * 0.8), Gfx.col(c, 1 - k)))
	anel(px, py, c, w * 0.7)
	Som.tocar("explosao", 0.9, clampf(60.0 / w + 0.6, 0.8, 1.6))

func bolt(x1: float, y1: float, x2: float, y2: float) -> void:
	var pts := PackedVector2Array()
	for i in 9:
		var k := i / 8.0
		var j := 0.0 if (i == 0 or i == 8) else 1.0
		pts.append(Vector2(x1 + (x2 - x1) * k + randf_range(-6, 6) * j, y1 + (y2 - y1) * k + randf_range(-6, 6) * j))
	add_fx(14, func(cv, k):
		cv.draw_polyline(pts, Gfx.col("#59d0ff", (1 - k) * 0.4), 4.0)
		cv.draw_polyline(pts, Gfx.col("#e6fdff", 1 - k), 2.0))

# ---------------- Progresso guardado ----------------
## Guarda nível, experiência e ouro. Pode ser chamado várias vezes.
func guardar() -> void:
	for p in players:
		var s := Save.pers(p.d.id)
		s.nivel = p.lvl; s.xp = p.xp
	Save.d.ouro = int(Save.d.ouro) + ouro
	ouro = 0
	Save.gravar()

func sair(acao: String) -> void:
	guardar()
	get_tree().paused = false
	finished.emit(acao)

func _concluir() -> void:
	var time := t / 60.0
	var rank := "C"
	if time < 170 and dmg_taken < 70: rank = "S"
	elif time < 260 and dmg_taken < 160: rank = "A"
	elif dmg_taken < 320: rank = "B"
	var bonus_xp := int({"S": 140, "A": 90, "B": 55, "C": 30}[rank] * D.premio)
	var bonus_ouro := int({"S": 110, "A": 70, "B": 45, "C": 25}[rank] * D.premio)
	var antes := []
	for p in players: antes.append([p.lvl, p.xp])
	ouro += bonus_ouro
	var ouro_total := ouro
	xp_ganho += bonus_xp
	for p in alive_players(): p.ganhar_xp(bonus_xp)
	var recorde := Save.resultado(fase.id, dif, rank, time)
	result = {"time": time, "dt": dmg_taken, "rank": rank, "xp": xp_ganho, "ouro": ouro_total, "recorde": recorde, "antes": antes}
	result_t = 0
	guardar()
	Som.tema(""); Som.tocar("vitoria")

# ---------------- Laço principal (60 passos fixos por segundo) ----------------
func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause") and result == null and not alive_players().is_empty():
		paused = not paused; pausa_sel = 0
		Som.tocar("confirma" if paused else "volta", 0.6)
	elif paused:
		_menu_pausa()
	if not paused:
		step()
	redraw()

func _menu_pausa() -> void:
	if Ui.cima():
		pausa_sel = (pausa_sel + PAUSA.size() - 1) % PAUSA.size(); Som.tocar("menu")
	if Ui.baixo():
		pausa_sel = (pausa_sel + 1) % PAUSA.size(); Som.tocar("menu")
	var item: String = PAUSA[pausa_sel]
	if item in ["musica", "efeitos", "tremor"]:
		var lado := (1 if Ui.dir() else 0) - (1 if Ui.esq() else 0)
		if lado == 0 and Ui.ok() and item == "tremor": lado = 1
		if lado != 0:
			Save.ajustar(item, lado); Som.tocar("menu")
	elif Ui.ok():
		Som.tocar("confirma", 0.7)
		match pausa_sel:
			0: paused = false
			4: sair("repetir")
			5: sair("lobby")
	if Ui.volta() and not Input.is_action_just_pressed("pause"):
		paused = false; Som.tocar("volta", 0.6)

func step() -> void:
	var everyone_dead := alive_players().is_empty()
	if everyone_dead:
		if all_dead_t == 0:
			Som.tema(""); Som.tocar("derrota")
		all_dead_t += 1
		if all_dead_t == 50: guardar()
		if all_dead_t > 60:
			if Input.is_action_just_pressed("restart"):
				sair("repetir"); return
			if Ui.ok():
				sair("lobby"); return
	if result != null:
		result_t += 1
		if result_t > 50:
			if Input.is_action_just_pressed("restart"):
				sair("repetir"); return
			if Ui.ok():
				sair("lobby"); return
	if dim_t > 0: dim_t -= 1
	if not corte.is_empty():
		corte.t += 1
		if corte.t > 52: corte = {}
	if not faixa.is_empty():
		faixa.t += 1
		if faixa.t > 70: faixa = {}
	if hitstop > 0:
		hitstop -= 1
		return
	if result == null and not everyone_dead:
		t += 1
	if intro_t > 0: intro_t -= 1
	for av in avisos: av.t += 1
	avisos = avisos.filter(func(av): return av.t < av.dur + 6)
	for p in players:
		p.tick()
	var lead := nearest_player(0) # quem está mais à frente define gatilhos
	for p in alive_players():
		if p.x > lead.x: lead = p
	if lead and not boss_started and sec_cleared(1) and lead.x > GameData.BOSS_TRIGGER_X:
		boss_started = true
		var b := add_enemy("boss", 2660, 2)
		b.y = -80; b.state = "intro"; b.active = true
		intro_t = 150
		hitboxes = hitboxes.filter(func(hb): return hb.owner == "p")
		projs = projs.filter(func(o): return o.owner == "p")
		Som.tema("chefe"); Som.tocar("chefe")
	for e in enemies:
		if e.hp > 0: e.tick()
	# dano por contato (só de quem ataca com o corpo)
	for p in alive_players():
		for e in enemies:
			if e.hp > 0 and e.hurt_t <= 0 and e.toca() and overlap(e, p):
				hurt_player(p, e.contact_damage(), 1 if p.cx() >= e.x + e.w / 2 else -1, 2.5, 2.5, e)
	# golpes
	for hb in hitboxes:
		if hb.has("place"): hb.place.call(hb)
		hb.t += 1
		if hb.get("rehit", 0) > 0 and hb.t % hb.rehit == 0:
			hb.hit.clear()
		var tg: Array = enemies if hb.owner == "p" else players
		for target in tg:
			if target.hp > 0 and not hb.hit.has(target.get_instance_id()) and overlap(hb, target):
				hb.hit[target.get_instance_id()] = true
				hit(target, hb, hb.x + hb.w / 2)
	hitboxes = hitboxes.filter(func(hb): return hb.t < hb.life)
	# projéteis
	for o in projs:
		o.t += 1; o.vy += o.grav; o.x += o.vx; o.y += o.vy
		var tg2: Array = enemies if o.owner == "p" else players
		for target in tg2:
			if o.get("dead", false): break
			if target.hp > 0 and not o.hit.has(target.get_instance_id()) and overlap(o, target):
				o.hit[target.get_instance_id()] = true
				hit(target, o, o.x + o.w / 2 - o.vx)
				if not o.get("pierce", false): o.dead = true
		if not o.get("no_ground", false) and o.y + o.h >= GameData.GROUND:
			o.dead = true
			if o.kind == "arrow" or o.kind == "rain": sparks(o.x + o.w / 2, GameData.GROUND, "#e8dcc0", 2, 1.2)
		if o.t > o.life or o.x < -50 or o.x > GameData.LEVEL_W + 50: o.dead = true
		if o.kind == "fire" and o.t % 2 == 1:
			parts.append({"x": o.x + 6, "y": o.y + 6, "vx": randf_range(-0.3, 0.3), "vy": randf_range(-0.6, 0), "life": 14.0, "c": "#ff8a3d" if randf() < 0.5 else "#ffd23f", "s": 3.0, "g": 0.0})
		if o.kind == "meteor":
			for i in 2:
				parts.append({"x": o.x + 11, "y": o.y + 11, "vx": randf_range(-0.5, 0.5), "vy": randf_range(-0.5, 0.5), "life": 20.0, "c": "#ff4d2e" if randf() < 0.5 else "#ffb347", "s": 4.0, "g": 0.0})
		if o.get("dead", false) and o.has("on_end"):
			o.on_end.call(o)
	projs = projs.filter(func(o): return not o.get("dead", false))
	for e in enemies:
		if e.hp <= 0: e.queue_free()
	enemies = enemies.filter(func(e): return e.hp > 0)
	for i in 2:
		if not cleared[i] and sec_cleared(i):
			cleared[i] = true
			show_msg("Área liberada! Avance" if i == 0 else "Caminho para a arena liberado", 150)
			Som.tocar("item", 0.8, 0.8)
	# timers, itens, partículas
	for tm in timers:
		tm.t -= 1
		if tm.t <= 0:
			tm.fn.call(); tm.done = true
	timers = timers.filter(func(tm): return not tm.get("done", false))
	_itens()
	for q in parts:
		q.x += q.vx; q.y += q.vy; q.vy += q.g; q.life -= 1
	parts = parts.filter(func(q): return q.life > 0)
	for n in nums: n.t += 1
	nums = nums.filter(func(n): return n.t < 45)
	for f in fx: f.t += 1
	fx = fx.filter(func(f): return f.t < f.life)
	if combo_t > 0:
		combo_t -= 1
		if combo_t == 0: combo = 0
	if msg_t > 0: msg_t -= 1
	# portal (fim da fase)
	if boss_dead and result == null:
		for p in alive_players():
			if p.x + p.w > GameData.PORTAL_X - 15 and p.x < GameData.PORTAL_X + 15:
				_concluir()
				break
	update_camera()
	if shake > 0:
		shake *= 0.85
		if shake < 0.3: shake = 0.0

func _itens() -> void:
	for k in pickups:
		k.t += 1; k.vy = minf(k.vy + 0.2, 4); k.y += k.vy
		k.x += k.get("vx", 0.0)
		if k.y + k.h > GameData.GROUND:
			k.y = GameData.GROUND - k.h; k.vy = (-k.vy * 0.45) if k.vy > 1.5 else 0.0
			if k.has("vx"): k.vx *= 0.6
		for p in alive_players():
			if k.get("dead", false): break
			# o ouro é puxado para o herói quando chega perto
			if k.kind == "ouro" and k.t > 20:
				var dx: float = p.cx() - (k.x + 3)
				var dy: float = (p.y + 12) - (k.y + 3)
				if absf(dx) < 46 and absf(dy) < 50:
					k.x += signf(dx) * minf(absf(dx), 3.2); k.y += signf(dy) * minf(absf(dy), 3.2); k.vy = 0.0
			if k.t > 15 and overlap(k, p):
				k.dead = true
				match k.kind:
					"hp":
						var cura := roundf(p.maxhp * 0.15)
						p.hp = minf(p.maxhp, p.hp + cura); num(p.x + 6, p.y - 6, "+%d" % int(cura), "#7dff8a"); Som.tocar("item")
					"mp":
						p.ganhar_mana(0.6); num(p.x + 6, p.y - 6, "Mana", "#7db8ff"); Som.tocar("item", 1.0, 1.2)
					"ouro":
						ouro += int(k.v); Som.tocar("moeda", 0.5)
	pickups = pickups.filter(func(k): return not k.get("dead", false) and k.t < 1200)

func update_camera() -> void:
	var ap := alive_players()
	if ap.is_empty(): ap = players
	var sum := 0.0
	var fsum := 0.0
	for p in ap:
		sum += p.cx(); fsum += p.facing
	var center := sum / ap.size()
	var target := center - GameData.W / 2 + (fsum / ap.size()) * 30
	var mn := 0.0
	var mx := GameData.LEVEL_W - GameData.W
	for b in barriers():
		if b < center: mn = maxf(mn, b - 20)
		else: mx = minf(mx, b + 20 - GameData.W)
	if boss_started and not boss_dead:
		mn = GameData.ARENA_L; mx = GameData.ARENA_L
	cam_x += (clampf(target, mn, maxf(mn, mx)) - cam_x) * 0.12

func redraw() -> void:
	var off := Vector2(randf_range(-shake, shake), randf_range(-shake, shake)) if (shake > 0 and not paused) else Vector2.ZERO
	camera.position = Vector2(roundf(cam_x) + GameData.W / 2, GameData.H / 2) - off
	bg.cam_x = cam_x
	bg.tremor = -off
	bg.chefe = clampf((cam_x - 2050) / 250.0, 0, 1)
	bg.queue_redraw()
	world.queue_redraw()
	for p in players: p.sync_node()
	for e in enemies: e.queue_redraw()
	fx_layer.queue_redraw()
	hud.queue_redraw()
