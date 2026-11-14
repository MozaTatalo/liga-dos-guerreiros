class_name Hero
extends Node2D
## Personagem jogável. Lê comandos de um PlayerInput, então vários heróis podem coexistir (multijogador).
##
## Combate de um botão: o ataque (Z) muda conforme a situação (chão, ar, correndo, com ↓),
## e segurar o ataque carrega a barra de mana até o nível 1, 2 ou 3 para soltar uma habilidade.

const CARGA_INI := 12      # passos segurando o ataque até começar a carregar
const CARGA_NIVEL := 24    # passos para carregar cada nível

## Poses do boneco (ângulos das juntas). "pre" é a preparação, "pos" é o golpe.
const POSE := {
	"lanca_pre": {"S": -0.9, "E": 0.2, "W": -1.5, "inc": -0.38, "sobe": -0.2, "cA": 0.95, "jA": -1.0, "cB": -0.5, "jB": -0.5, "tor": 0.5},
	"lanca_pos": {"S": 3.05, "E": 0.05, "W": -1.38, "inc": 0.2, "sobe": 0.06, "cA": 0.3, "jA": -0.1, "cB": -0.35, "tor": -0.4, "cab": -0.2},
	"escudo_pre": {"S2": 0.2, "E2": 1.9, "S": -0.6, "E": 0.6, "tor": -0.5, "inc": -0.1, "cA": 0.5, "cB": -0.4},
	"escudo_pos": {"S2": 1.45, "E2": 0.25, "S": -0.9, "E": 0.4, "tor": 0.55, "inc": -0.32, "cA": 0.85, "jA": -0.7, "cB": -0.75, "jB": -0.1, "sobe": -0.1},
	"mergulho": {"S": 0.75, "E": 0.05, "W": -0.35, "S2": -0.8, "E2": 0.6, "inc": -0.55, "cA": 0.9, "jA": -1.5, "cB": -0.1, "jB": -0.9, "sobe": 0.0},
	"tiro_pre": {"S": 1.5, "E": 0.05, "W": -1.3, "S2": 1.1, "E2": 2.0, "tor": 0.55, "inc": 0.02, "cA": 0.45, "jA": -0.2, "cB": -0.45},
	"tiro_pos": {"S": 1.55, "E": 0.0, "W": -1.3, "S2": 0.7, "E2": 0.9, "tor": 0.35, "inc": 0.06, "cA": 0.45, "jA": -0.2, "cB": -0.45},
	"tiro_baixo_pre": {"S": 0.9, "E": 0.05, "W": -1.3, "S2": 0.6, "E2": 1.9, "tor": 0.5, "inc": -0.25, "cA": 0.8, "jA": -1.2, "cB": -0.2, "jB": -0.8},
	"tiro_baixo_pos": {"S": 0.9, "E": 0.0, "W": -1.3, "S2": 0.3, "E2": 0.8, "tor": 0.3, "inc": -0.2, "cA": 0.8, "jA": -1.2, "cB": -0.2, "jB": -0.8},
	"chute_pre": {"cA": 0.5, "jA": -1.6, "inc": 0.1, "S": -0.5, "E": 0.5, "S2": -0.4, "E2": 0.8, "cB": -0.15, "jB": -0.1},
	"chute_pos": {"cA": 1.55, "jA": -0.02, "inc": 0.32, "S": -0.8, "E": 0.3, "S2": -0.7, "E2": 0.4, "cB": -0.2, "jB": -0.05, "sobe": 0.02},
	"chute_alto": {"cA": 2.3, "jA": -0.02, "inc": 0.5, "S": -1.0, "E": 0.3, "S2": -0.9, "E2": 0.4, "cB": -0.1, "jB": -0.05, "sobe": 0.06, "cab": -0.2},
	"rasteira": {"cA": 1.35, "jA": -0.02, "inc": 0.55, "S": -1.1, "E": 0.2, "S2": -1.0, "E2": 0.3, "cB": -0.9, "jB": -1.6, "sobe": -0.42},
	"conjura_pre": {"S": 2.5, "E": 0.5, "W": -1.2, "S2": 0.6, "E2": 1.4, "inc": 0.1, "cA": 0.3, "cB": -0.35},
	"conjura_pos": {"S": 1.35, "E": 0.05, "W": -0.9, "S2": 1.2, "E2": 0.3, "inc": -0.15, "tor": 0.25, "cA": 0.6, "jA": -0.4, "cB": -0.55},
	"pilar_pre": {"S": 0.5, "E": 0.3, "W": -1.5, "S2": 0.4, "E2": 0.6, "inc": -0.35, "sobe": -0.18, "cA": 0.8, "jA": -0.9, "cB": -0.5, "jB": -0.5},
	"pilar_pos": {"S": 2.9, "E": 0.05, "W": -1.38, "S2": 2.6, "E2": 0.1, "inc": 0.18, "sobe": 0.05, "cA": 0.25, "cB": -0.3, "cab": -0.25},
	"carga": {"S": 0.95, "E": 1.7, "W": -1.5, "S2": 0.9, "E2": 1.6, "inc": -0.16, "sobe": -0.12, "cA": 0.62, "jA": -0.7, "cB": -0.6, "jB": -0.35, "cab": 0.15},
	"vitoria": {"S": 3.0, "E": 0.08, "W": -1.38, "S2": 0.5, "E2": 1.5, "inc": 0.1, "cA": 0.3, "cB": -0.3, "cab": -0.2, "tor": -0.2},
	"giro": {"S": 1.55, "E": 0.02, "W": -1.38, "S2": -0.6, "E2": 0.8, "inc": -0.05, "cA": 0.4, "cB": -0.4, "sobe": -0.05},
}

## Golpes de cada classe. dur: passos; hit: passo(s) do acerto; next: golpe seguinte se apertar de novo;
## anim: número (golpe de espada 0, 1 ou 2 do boneco) ou [pose_pre, pose_pos].
const GOLPES := {
	"guardiao": {
		"g1": {"dur": 17, "hit": [5], "next": "g2", "anim": 0},
		"g2": {"dur": 17, "hit": [5], "next": "g3", "anim": 1},
		"g3": {"dur": 19, "hit": [6], "next": "g4", "anim": 0},
		"g4": {"dur": 30, "hit": [9], "next": "", "anim": 2},
		"lanca": {"dur": 28, "hit": [8], "next": "", "anim": ["lanca_pre", "lanca_pos"]},
		"corrida": {"dur": 26, "hit": [5], "next": "", "anim": ["escudo_pre", "escudo_pos"]},
		"ar1": {"dur": 15, "hit": [4], "next": "ar2", "anim": 0},
		"ar2": {"dur": 15, "hit": [4], "next": "ar3", "anim": 1},
		"ar3": {"dur": 22, "hit": [7], "next": "", "anim": 2},
		"mergulho": {"dur": 999, "hit": [3], "next": "", "anim": ["mergulho", "mergulho"]},
	},
	"cacadora": {
		"g1": {"dur": 15, "hit": [5], "next": "g2", "anim": ["tiro_pre", "tiro_pos"]},
		"g2": {"dur": 15, "hit": [5], "next": "g3", "anim": ["tiro_pre", "tiro_pos"]},
		"g3": {"dur": 17, "hit": [6], "next": "g4", "anim": ["chute_pre", "chute_pos"]},
		"g4": {"dur": 30, "hit": [11], "next": "", "anim": ["tiro_pre", "tiro_pos"]},
		"lanca": {"dur": 28, "hit": [7], "next": "", "anim": ["chute_pre", "chute_alto"]},
		"corrida": {"dur": 26, "hit": [4, 12], "next": "", "anim": ["rasteira", "rasteira"]},
		"ar1": {"dur": 14, "hit": [5], "next": "ar2", "anim": ["tiro_baixo_pre", "tiro_baixo_pos"]},
		"ar2": {"dur": 14, "hit": [5], "next": "ar3", "anim": ["tiro_baixo_pre", "tiro_baixo_pos"]},
		"ar3": {"dur": 20, "hit": [6], "next": "", "anim": ["tiro_baixo_pre", "tiro_baixo_pos"]},
		"mergulho": {"dur": 24, "hit": [7], "next": "", "anim": ["tiro_baixo_pre", "tiro_baixo_pos"]},
	},
	"arcanista": {
		"g1": {"dur": 17, "hit": [5], "next": "g2", "anim": 0},
		"g2": {"dur": 17, "hit": [5], "next": "g3", "anim": 1},
		"g3": {"dur": 20, "hit": [7], "next": "g4", "anim": ["conjura_pre", "conjura_pos"]},
		"g4": {"dur": 32, "hit": [11], "next": "", "anim": ["pilar_pre", "conjura_pos"]},
		"lanca": {"dur": 30, "hit": [10], "next": "", "anim": ["pilar_pre", "pilar_pos"]},
		"corrida": {"dur": 24, "hit": [6], "next": "", "anim": ["conjura_pre", "conjura_pos"]},
		"ar1": {"dur": 17, "hit": [6], "next": "ar2", "anim": ["conjura_pre", "conjura_pos"]},
		"ar2": {"dur": 17, "hit": [6], "next": "ar3", "anim": ["conjura_pre", "conjura_pos"]},
		"ar3": {"dur": 22, "hit": [8], "next": "", "anim": ["conjura_pre", "conjura_pos"]},
		"mergulho": {"dur": 26, "hit": [9], "next": "", "anim": ["pilar_pos", "pilar_pre"]},
	},
}

var game
var d: Dictionary
var input: PlayerInput
var player_index := 0

var x := 60.0
var y := 0.0
var w := 12.0
var h := 24.0
var vx := 0.0
var vy := 0.0
var facing := 1
var on_ground := false
var drop_t := 0
var hp := 0.0
var maxhp := 0.0
var hp_rastro := 0.0       # vida "antiga" que desce devagar na barra
var mp := 1.0              # 0 a 3 níveis
var lvl := 1
var xp := 0
var atk := 1.0             # multiplicador de dano do nível
var state := "idle"
var state_t := 0
var mv := ""               # golpe atual
var M := {}                # dados do golpe atual
var queued := ""
var hold_t := 0
var charge := 0.0
var charge_lv := 0
var running := false
var tap_dir := 0
var tap_t := 0
var air_n := 0             # golpes no ar usados neste pulo
var jumps := 0
var invuln := 0
var dash_cd := 0
var skill := -1
var dead := false
var dead_t := 0
var anim := 0
var deny_t := 0
var subiu_t := 0           # efeito de subir de nível
var view: HeroView

func _exit_tree() -> void:
	if game and game.bg is Cenario3D:
		game.bg.sombra(self, 0, 0, 0, false)

func setup(g, def: Dictionary, inp: PlayerInput, index := 0) -> void:
	game = g; d = def; input = inp; player_index = index
	x = 60.0 + index * 20.0
	y = GameData.GROUND - h
	var s := Save.pers(d.id)
	lvl = int(s.nivel); xp = int(s.xp)
	_atributos()
	hp = maxhp; hp_rastro = hp
	view = HeroView.new(d)
	add_child(view)

func _atributos() -> void:
	maxhp = roundf(d.hp * Save.mult_vida(lvl))
	atk = Save.mult_dano(lvl)

func cx() -> float:
	return x + w / 2.0

func front(ox: float, oy: float, bw: float, bh: float) -> Dictionary:
	return {"x": (x + w + ox) if facing > 0 else (x - ox - bw), "y": y + oy, "w": bw, "h": bh}

func follow(ox: float, oy: float, bw: float, bh: float) -> Callable:
	return func(o: Dictionary) -> void:
		o.merge(front(ox, oy, bw, bh), true)

func set_idle() -> void:
	state = "idle"; state_t = 0; skill = -1; mv = ""; queued = ""

## Quantos níveis de habilidade este herói já pode usar.
func niveis() -> int:
	return clampi(lvl, 1, 3)

func ganhar_xp(n: int) -> void:
	if lvl >= Save.NIVEL_MAX: return
	xp += n
	while lvl < Save.NIVEL_MAX and xp >= Save.xp_para(lvl):
		xp -= Save.xp_para(lvl); lvl += 1
		_atributos()
		hp = maxhp; mp = minf(GameData.MANA_MAX, mp + 1.0); subiu_t = 90
		Som.tocar("nivel")
		game.callout(cx(), y - 22, "NÍVEL %d!" % lvl, "#ffd23f")
		game.anel(cx(), y + h / 2, "#ffd23f", 46.0)
		game.sparks(cx(), y + 8, "#ffd23f", 26, 4)
		if lvl <= 3:
			game.show_msg("Habilidade nova: %s" % d.skills[lvl - 1].n, 170)

func ganhar_mana(n: float) -> void:
	mp = minf(GameData.MANA_MAX, mp + n)

# ---------------- Golpes ----------------
func start_move(id: String) -> void:
	state = "attack"; state_t = 0; mv = id; M = GOLPES[d.id][id]; queued = ""
	if input.held("left"): facing = -1
	if input.held("right"): facing = 1
	if id.begins_with("ar") or id == "mergulho": air_n += 1
	match id:
		"corrida":
			vx = facing * 4.2
		"mergulho":
			if d.id == "guardiao":
				vy = 2.0; vx = facing * 1.2
			else:
				vy = minf(vy, -1.0)

## Qual golpe sai ao apertar o ataque agora.
func escolher_golpe() -> String:
	if not on_ground:
		if input.held("down"): return "mergulho"
		return "ar1"
	if input.held("down"): return "lanca"
	if running or state == "dash": return "corrida"
	return "g1"

func tick() -> void:
	anim += 1
	if dash_cd > 0: dash_cd -= 1
	if invuln > 0: invuln -= 1
	if deny_t > 0: deny_t -= 1
	if subiu_t > 0: subiu_t -= 1
	if tap_t > 0: tap_t -= 1
	hp_rastro = maxf(hp, hp_rastro - maxhp * 0.006)
	if dead:
		dead_t += 1; vx *= 0.92
		game.physics(self)
		return
	if game.result != null:
		vx *= 0.8; state = "idle"
		game.physics(self)
		return
	ganhar_mana(0.0009)
	state_t += 1
	hold_t = hold_t + 1 if input.held("attack") else 0
	var L := input.held("left")
	var R := input.held("right")
	for dr in [-1, 1]:
		if input.tapped("left" if dr < 0 else "right"):
			if tap_dir == dr and tap_t > 0: running = true
			tap_dir = dr; tap_t = 14
	if not L and not R: running = false
	match state:
		"hurt":
			vx *= 0.85
			if state_t > 18: set_idle()
		"attack":
			_tick_golpe()
		"charge":
			_tick_carga(L, R)
		"skill":
			if on_ground and not skill_moves(skill): vx *= 0.7
			skill_update(skill, state_t)
			if state == "skill" and state_t >= d.skills[skill].dur: set_idle()
		"dash":
			vx = 4.8 * facing
			if state_t % 2 == 1: game.ghost(self)
			if input.tapped("attack") and state_t > 2 and on_ground:
				start_move("corrida")
			elif state_t > 12:
				set_idle(); vx = 1.5 * facing; running = L or R
		_:
			var veloc: float = float(d.speed) * (1.65 if running else 1.0)
			var tv := ((1.0 if R else 0.0) - (1.0 if L else 0.0)) * veloc
			vx += (tv - vx) * 0.3
			if L and not R: facing = -1
			if R and not L: facing = 1
			if not on_ground: state = "jump"
			elif absf(tv) > 0: state = "run"
			else: state = "idle"
			if running and on_ground and anim % 7 == 0: game.dust(cx() - facing * 4, y + h, 1)
			if input.tapped("jump"):
				_pular()
			if input.tapped("attack"):
				var id := escolher_golpe()
				if id.begins_with("ar") and air_n >= 3: pass
				elif id == "mergulho" and air_n >= 4: pass
				else: start_move(id)
			elif input.tapped("dash") and dash_cd <= 0:
				_esquivar()
			elif hold_t >= CARGA_INI:
				_comecar_carga()
	var was_air := not on_ground
	var vy_ant := vy
	game.physics(self)
	if on_ground:
		jumps = 0; air_n = 0
		if was_air:
			game.dust(cx(), y + h, 3)
			if state == "attack" and mv == "mergulho" and d.id == "guardiao": _pouso_mergulho(vy_ant)
			elif state == "attack" and (mv.begins_with("ar") or mv == "mergulho"): set_idle()
	game.apply_barriers(self)

func _pular() -> void:
	if input.held("down") and on_ground and y + h < GameData.GROUND - 1:
		drop_t = 10; y += 1
	elif on_ground:
		vy = -6.3; jumps = 1
		game.dust(cx(), y + h); Som.tocar("pulo", 0.8)
	elif jumps < 2:
		vy = -5.5; jumps = 2
		game.sparks(cx(), y + h, "#ffffff", 5, 1.5); Som.tocar("pulo", 0.8, 1.25)

func _esquivar() -> void:
	state = "dash"; state_t = 0; dash_cd = 36; mv = ""
	if input.held("left"): facing = -1
	if input.held("right"): facing = 1
	invuln = maxi(invuln, 14); vy = minf(vy, 0.0)
	Som.tocar("esquiva")

func _tick_golpe() -> void:
	var no_ar := not on_ground
	if on_ground and mv != "corrida": vx *= 0.75
	if mv == "corrida": vx *= 0.93
	if no_ar and mv != "mergulho":
		vy = minf(vy, 0.9)    # golpes no ar seguram a queda
		vx *= 0.9
	if mv == "mergulho" and d.id == "guardiao":
		vy = minf(vy + 0.9, 8.5)
		if state_t % 2 == 0: game.ghost(self)
	for i in M.hit.size():
		if state_t == M.hit[i]: attack_hit(i)
	if state != "attack": return
	if input.tapped("attack") and state_t > 2:
		if no_ar and input.held("down"): queued = "mergulho"
		elif not no_ar and input.held("down") and mv != "lanca": queued = "lanca"
		else: queued = "seguir"
	var ultimo: int = M.hit[-1]
	# cancelamentos: esquiva e pulo depois do acerto
	if state_t > ultimo + 2 and mv != "mergulho":
		if input.tapped("dash") and dash_cd <= 0:
			_esquivar(); return
		if input.tapped("jump") and (on_ground or jumps < 2):
			set_idle(); _pular(); state = "jump"; return
	if state_t >= ultimo + 5 and queued != "" and mv != "mergulho":
		var prox: String = M.next if queued == "seguir" else queued
		if prox == "mergulho" and air_n >= 4: prox = ""
		if prox.begins_with("ar") and on_ground: prox = "g1"
		if prox != "":
			start_move(prox); return
	if state_t >= M.dur:
		if hold_t >= CARGA_INI and queued == "": _comecar_carga()
		else: set_idle()

func _comecar_carga() -> void:
	if mp < 1.0:
		if deny_t <= 0:
			deny_t = 40; Som.tocar("volta", 0.7)
		if state == "attack": set_idle()
		return
	state = "charge"; state_t = 0; charge = 0.0; charge_lv = 0; mv = ""
	Som.tocar("carga", 0.7)

func _tick_carga(L: bool, R: bool) -> void:
	if on_ground: vx *= 0.7
	else:
		vx *= 0.9; vy = minf(vy, 0.7)
	if L and not R: facing = -1
	if R and not L: facing = 1
	var lim := mini(int(mp + 0.0001), niveis())
	charge = minf(charge + 1.0 / CARGA_NIVEL, float(lim))
	var lv := int(charge + 0.0001)
	if lv > charge_lv:
		charge_lv = lv
		var c: String = d.skills[lv - 1].c
		game.anel(cx(), y + h / 2, c, 22.0 + lv * 8.0)
		game.sparks(cx(), y + h / 2, c, 8 + lv * 4, 2.5)
		Som.tocar("carga_nivel", 0.8, 0.85 + lv * 0.15, 0.0)
	elif state_t % 3 == 0:
		# partículas sendo puxadas para o herói
		var a := randf_range(0, TAU)
		var r := randf_range(18, 30)
		game.parts.append({"x": cx() + cos(a) * r, "y": y + h / 2 + sin(a) * r, "vx": -cos(a) * r / 12.0, "vy": -sin(a) * r / 12.0, "life": 11.0,
			"c": d.skills[clampi(lv, 0, 2)].c, "s": 1.6, "g": 0.0})
	if input.tapped("dash") and dash_cd <= 0:
		_esquivar(); return
	if not input.held("attack"):
		if charge_lv >= 1: cast(charge_lv - 1)
		else: set_idle()

func cast(i: int) -> void:
	var sk: Dictionary = d.skills[i]
	mp = maxf(0.0, mp - float(i + 1))
	state = "skill"; skill = i; state_t = 0; charge = 0.0; charge_lv = 0
	game.callout(cx(), y - 16, sk.n + "!", sk.c)
	Som.tocar("magia", 0.9, 1.1 - i * 0.12)
	if i == 2: game.suprema(self, sk)
	skill_start(i)

# ---------------- Acertos dos golpes básicos ----------------
## Caixa de golpe corpo a corpo na frente do herói. cx_ = [dx, dy, largura, altura].
func golpe(dano: float, cx_: Array, o := {}) -> void:
	var hb := {"owner": "p", "src": self, "dmg": dano * atk, "kbx": 1.4, "launch": 0.0, "life": 5, "dir": facing}
	hb.merge(o, true)
	hb.merge(front(cx_[0], cx_[1], cx_[2], cx_[3]), true)
	game.spawn_hitbox(hb)

func tiro(dano: float, o := {}) -> void:
	var p := {"owner": "p", "src": self, "x": cx() + facing * 6 - 5, "y": y + 8, "w": 12.0, "h": 3.0, "vx": 6.8 * facing, "vy": 0.0,
		"dmg": dano * atk, "kbx": 1.6, "launch": 0.0, "life": 70, "kind": "arrow", "dir": facing}
	p.merge(o, true)
	game.spawn_proj(p)
	Som.tocar("flecha", 0.7)

func corte(r: float, s: int, c = "#ffffff") -> void:
	var px := cx()
	var py := y + 12
	var f := facing
	game.add_fx(9, func(cv, k): Gfx.slash(cv, px, py, f, r, s, k, c))

func attack_hit(i: int) -> void:
	var f := facing
	match d.id:
		"guardiao": _hit_guardiao(f)
		"cacadora": _hit_cacadora(f, i)
		_: _hit_arcanista(f)

func _hit_guardiao(f: int) -> void:
	match mv:
		"g1", "g2", "g3":
			if on_ground: vx = f * 1.6
			golpe(10 if mv != "g3" else 12, [-4, 0, 26, 20])
			corte(19.0, 1 if mv == "g2" else 0); Som.tocar("golpe")
		"g4":
			if on_ground: vx = f * 2.6
			golpe(24, [-4, -8, 30, 30], {"kbx": 4.6, "launch": 3.4, "heavy": true})
			corte(25.0, 2, "#ffe9a8"); Som.tocar("golpe2")
		"lanca":
			golpe(14, [-6, -14, 26, 38], {"kbx": 0.5, "launch": 7.2, "heavy": true})
			corte(24.0, 1, "#bfe4ff"); Som.tocar("golpe2", 1.0, 1.2)
		"corrida":
			invuln = maxi(invuln, 8)
			golpe(16, [-4, 0, 16, 24], {"kbx": 3.8, "launch": 2.6, "heavy": true, "life": 12, "place": follow(-4, 0, 16, 24)})
			game.dust(cx(), y + h, 4); Som.tocar("golpe2", 0.9, 0.9)
		"ar1", "ar2":
			golpe(10, [-4, -4, 26, 26], {"kbx": 0.6, "launch": 2.4})
			corte(19.0, 1 if mv == "ar2" else 0); Som.tocar("golpe")
			vy = -1.4
		"ar3":
			golpe(16, [-4, -8, 28, 34], {"kbx": 2.0, "launch": -6.0, "heavy": true})   # crava o inimigo no chão
			corte(24.0, 2, "#ffe9a8"); Som.tocar("golpe2")
		"mergulho":
			golpe(8, [-6, 4, 24, 26], {"kbx": 0.4, "launch": -4.0, "life": 40, "rehit": 8, "place": follow(-6, 4, 24, 26)})
			Som.tocar("esquiva", 0.8, 0.7)

func _pouso_mergulho(queda: float) -> void:
	# onda de choque ao cair com a espada
	var eu := self
	game.hitboxes = game.hitboxes.filter(func(hb): return hb.get("src") != eu or not hb.has("rehit"))
	game.spawn_hitbox({"owner": "p", "src": self, "dmg": (14 + minf(queda, 8.5) * 1.2) * atk, "kbx": 2.5, "launch": 5.2, "life": 5, "dir": 0, "heavy": true,
		"x": cx() - 34, "y": y + h - 16, "w": 68.0, "h": 18.0})
	game.shake = maxf(game.shake, 5); game.dust(cx(), y + h, 12)
	game.anel(cx(), y + h, "#bfe4ff", 38.0, 0.35)
	Som.tocar("acerto2", 0.9, 0.8)
	state_t = 0; mv = "pouso"; M = {"dur": 14, "hit": [99], "next": "", "anim": ["mergulho", "mergulho"]}

func _hit_cacadora(f: int, i: int) -> void:
	match mv:
		"g1", "g2":
			tiro(8)
			if on_ground: vx = -f * 0.5
		"g3":
			golpe(9, [-4, 2, 20, 18], {"kbx": 3.4, "launch": 1.6})   # chute que afasta
			corte(15.0, 0, "#c9f2c0"); Som.tocar("golpe", 1.0, 1.3)
			if on_ground: vx = f * 1.2
		"g4":
			tiro(20, {"pierce": true, "w": 18.0, "kbx": 4.2, "launch": 2.2, "color": "#ffd23f", "heavy": true, "vx": 8.0 * f})
			if on_ground: vx = -f * 2.2
			Som.tocar("golpe2", 0.7, 1.4)
		"lanca":
			golpe(12, [-6, -14, 22, 38], {"kbx": 0.4, "launch": 7.0, "heavy": true})
			corte(22.0, 1, "#c9f2c0"); Som.tocar("golpe2", 1.0, 1.3)
			vy = -3.2; on_ground = false
		"corrida":
			if i == 0:
				golpe(7, [-4, 10, 20, 14], {"kbx": 2.4, "launch": 1.2, "life": 8, "place": follow(-4, 10, 20, 14)})
				Som.tocar("golpe", 1.0, 1.2)
			else:
				golpe(8, [-4, 6, 22, 18], {"kbx": 1.0, "launch": 4.6, "heavy": true})
		"ar1", "ar2":
			tiro(8, {"vx": 6.2 * f, "vy": 3.0})
			vy = -1.6; vx = -f * 0.6
		"ar3":
			for a in [2.0, 3.4, 4.8]:
				tiro(8, {"vx": 6.0 * f, "vy": a, "pierce": true, "color": "#ffd23f"})
			vy = -2.4; vx = -f * 1.4
		"mergulho":
			for a in [-2.2, -1.1, 0.0, 1.1, 2.2]:   # leque para baixo
				tiro(7, {"vx": a + f * 0.6, "vy": 6.5, "w": 3.0, "h": 12.0, "kind": "rain", "launch": 1.5})
			vy = -4.6

func _hit_arcanista(f: int) -> void:
	var px := cx()
	match mv:
		"g1", "g2":
			if on_ground: vx = f * 1.0
			golpe(8, [-4, 0, 22, 20], {"kbx": 1.2})
			corte(16.0, 1 if mv == "g2" else 0, "#59d0ff"); Som.tocar("golpe", 1.0, 1.15)
		"g3":
			_raio_arcano(12, 5.0, 0.0)
		"g4":
			game.explode(px + f * 30, y + 10, 50, 44, 20 * atk, 4.2, "#8fd8ff", self)
		"lanca":
			_pilar(px + f * 30)
		"corrida":
			golpe(13, [-4, 0, 30, 22], {"kbx": 3.6, "launch": 2.4, "heavy": true})
			var ex := px + f * 22
			var ey := y + 10
			game.sparks(ex, ey, "#59d0ff", 14, 3.5); game.anel(ex, ey, "#59d0ff", 20.0)
			Som.tocar("magia", 0.7, 1.4)
		"ar1", "ar2":
			_raio_arcano(9, 5.0, 0.6); vy = -1.2
		"ar3":
			_raio_arcano(14, 5.5, 1.2, true); vy = -2.0; vx = -f * 1.2
		"mergulho":
			vy = -3.4
			var eu := self
			game.spawn_proj({"owner": "p", "src": self, "x": px - 6, "y": y + h, "w": 12.0, "h": 12.0, "vx": f * 1.4, "vy": 5.5,
				"dmg": 10 * atk, "kbx": 1.0, "launch": 0.0, "life": 90, "kind": "fire", "dir": f,
				"on_end": func(o): eu.game.explode(o.x + 6, o.y + 6, 60, 44, 18 * eu.atk, 5.0, "#ff8a3d", eu)})
			Som.tocar("magia", 0.8, 0.9)

func _raio_arcano(dano: float, v: float, vy_: float, forte := false) -> void:
	game.spawn_proj({"owner": "p", "src": self, "x": cx() + facing * 8 - 5, "y": y + 6, "w": 10.0, "h": 8.0, "vx": v * facing, "vy": vy_,
		"dmg": dano * atk, "kbx": 2.6 if forte else 1.6, "launch": 2.0 if forte else 0.0, "life": 80, "kind": "bolt", "dir": facing, "heavy": forte})
	Som.tocar("magia", 0.6, 1.5)

## Pilar de runas que sobe do chão e lança os inimigos.
func _pilar(px: float) -> void:
	var base := y + h
	game.spawn_hitbox({"owner": "p", "src": self, "dmg": 13 * atk, "kbx": 0.3, "launch": 7.4, "life": 8, "dir": facing, "heavy": true,
		"x": px - 13, "y": base - 60, "w": 26.0, "h": 60.0})
	game.add_fx(18, func(cv, k):
		var a: float = 1.0 - k
		var alt: float = 62.0 * minf(1.0, k * 4.0)
		cv.draw_rect(Rect2(px - 11 * a, base - alt, 22 * a, alt), Color(0.35, 0.8, 1.0, 0.45 * a))
		cv.draw_rect(Rect2(px - 5 * a, base - alt, 10 * a, alt), Color(0.9, 1.0, 1.0, 0.8 * a)))
	game.anel(px, base, "#59d0ff", 26.0, 0.35)
	game.sparks(px, base - 20, "#9ff0ff", 12, 3.5)
	Som.tocar("magia", 0.9, 0.8)

# ---------------- Habilidades (nível 1, 2 e 3 da barra) ----------------
func skill_moves(i: int) -> bool:
	return d.id == "guardiao" or (d.id == "cacadora" and i == 1)

func skill_start(i: int) -> void:
	var me := self
	match d.id:
		"guardiao":
			if i == 0:
				invuln = maxi(invuln, 20)
				game.spawn_hitbox({"owner": "p", "src": self, "skill": true, "dmg": 26 * atk, "kbx": 5.2, "launch": 3.6, "life": 16, "heavy": true, "dir": facing, "place": follow(-4, 0, 16, 24)})
				Som.tocar("golpe2")
			elif i == 1:
				vy = -6.6; vx = 1.4 * facing; invuln = maxi(invuln, 24)
				game.spawn_hitbox({"owner": "p", "src": self, "skill": true, "dmg": 36 * atk, "kbx": 0.8, "launch": 8.2, "life": 14, "heavy": true, "dir": facing, "place": follow(-6, -16, 26, 42)})
				corte(30.0, 1, "#bfe4ff"); Som.tocar("golpe2", 1.0, 1.2)
			else:
				invuln = maxi(invuln, 90)
				game.spawn_hitbox({"owner": "p", "src": self, "skill": true, "dmg": 9 * atk, "kbx": -1.6, "launch": 2.2, "life": 60, "rehit": 6, "dir": 0,
					"place": func(o: Dictionary) -> void:
						o.x = me.cx() - 44; o.y = me.y - 14; o.w = 88.0; o.h = 44.0})
		"cacadora":
			if i == 1:
				vx = -3.6 * facing; vy = -4.6; invuln = maxi(invuln, 26)
			elif i == 2:
				invuln = maxi(invuln, 50)
		_:
			if i == 2: invuln = maxi(invuln, 50)

func skill_update(i: int, t: int) -> void:
	var f := facing
	var me := self
	match d.id:
		"guardiao":
			if i == 0:
				vx = 5.4 * f if t < 15 else vx * 0.6
				if t % 2 == 1: game.ghost(self)
			elif i == 1:
				if t % 2 == 1 and t < 20: game.ghost(self)
			elif i == 2:
				if t < 60:
					vx = ((1.0 if input.held("right") else 0.0) - (1.0 if input.held("left") else 0.0)) * 1.2
					if t % 8 == 0:
						Som.tocar("golpe", 0.8, 1.0 + t * 0.006)
						var px := cx()
						var py := y + 10
						var s := (t / 8) % 2
						game.add_fx(10, func(cv, k): Gfx.slash(cv, px, py, 1 if s == 0 else -1, 40.0, 0, k, "#9fd3ff"))
				elif t == 62:
					vx = 0
					game.explode(cx(), y + 8, 130, 70, 52 * atk, 6.4, "#9fd3ff", self)
					game.anel(cx(), y + 8, "#ffffff", 80.0, 0.5)
		"cacadora":
			if i == 0 and t == 6:
				for v in [-1.0, 0.0, 1.0]:
					tiro(15, {"vy": v, "skill": true, "launch": 1.5})
			elif i == 1 and t == 9:
				tiro(46, {"pierce": true, "w": 26.0, "h": 5.0, "kbx": 4.6, "launch": 3.0, "color": "#ffd23f", "skill": true, "heavy": true, "vx": 9.0 * f, "life": 90})
				game.anel(cx() + f * 10, y + 9, "#ffd23f", 20.0)
				Som.tocar("golpe2", 0.9, 1.5)
			elif i == 2 and t == 10:
				var bx := cx()
				for n in 36:
					var off := randf_range(-20, 230)
					game.timers.append({"t": 2 + n * 2, "fn": func():
						me.game.spawn_proj({"owner": "p", "src": me, "skill": true, "x": bx + f * off, "y": -10.0 - randf() * 30, "w": 3.0, "h": 12.0, "vx": 0.7 * f, "vy": 8.0,
							"dmg": 12 * me.atk, "kbx": 0.4, "launch": 1.8, "life": 60, "kind": "rain", "dir": f})
						if n % 4 == 0: Som.tocar("flecha", 0.5)})
		"arcanista":
			if i == 0 and t == 8:
				game.spawn_proj({"owner": "p", "src": self, "skill": true, "x": cx() + f * 8 - 6, "y": y + 5, "w": 12.0, "h": 12.0, "vx": 3.6 * f, "vy": 0.0,
					"dmg": 26 * atk, "kbx": 3.0, "launch": 2.5, "life": 120, "kind": "fire", "dir": f, "heavy": true,
					"on_end": func(o): me.game.explode(o.x + 6, o.y + 6, 54, 46, 16 * me.atk, 3.5, "#ff8a3d", me)})
			elif i == 1 and t == 10:
				chain_lightning()
			elif i == 2 and t == 12:
				var sx := x - f * 70
				var sy := -50.0
				var tx := x + f * 120
				var N := 34.0
				game.spawn_proj({"owner": "p", "src": self, "skill": true, "x": sx, "y": sy, "w": 22.0, "h": 22.0, "vx": (tx - sx) / N, "vy": (GameData.GROUND - 22 - sy) / N,
					"dmg": 24 * atk, "kbx": 2.0, "launch": 2.0, "life": 200, "pierce": true, "kind": "meteor", "dir": f,
					"on_end": func(o):
						me.game.explode(o.x + 11, GameData.GROUND - 24, 150, 80, 96 * me.atk, 7.0, "#ff4d2e", me)
						me.game.shake = 14.0})

func chain_lightning() -> void:
	var c0 := cx()
	var c1 := y + 8
	var list := []
	for e in game.enemies:
		if e.hp > 0 and Vector2(e.x + e.w / 2 - c0, e.y + e.h / 2 - c1).length() < 250:
			list.append(e)
	list.sort_custom(func(a, b): return absf(a.x - c0) < absf(b.x - c0))
	list = list.slice(0, 5)
	var px := c0 + facing * 8
	var py := c1 - 6
	Som.tocar("explosao", 0.7, 1.6)
	if list.is_empty():
		game.bolt(px, py, px + facing * 70, py + 20)
	for e in list:
		var ex: float = e.x + e.w / 2
		var ey: float = e.y + e.h / 2
		game.bolt(px, py, ex, ey)
		px = ex; py = ey
		game.damage_enemy(e, {"dmg": 38 * atk, "kbx": 1.0, "launch": 4.5, "heavy": true, "skill": true, "src": self}, 1 if ex > c0 else -1)
		game.sparks(ex, ey, "#9ff0ff", 10, 3)

# ---------------- Desenho ----------------
func _draw() -> void:
	if state == "charge":
		# aura de carga: anel que cresce com o nível
		var c := Color(d.skills[clampi(charge_lv, 0, 2)].c)
		var k := (charge - floorf(charge)) if charge_lv < mini(int(mp + 0.0001), niveis()) else 1.0
		var r := 10.0 + charge * 5.0
		draw_set_transform(Vector2(0, -1), 0.0, Vector2(1, 0.32))
		draw_arc(Vector2.ZERO, r, 0, TAU, 28, Color(c.r, c.g, c.b, 0.55), 1.6)
		draw_arc(Vector2.ZERO, r + 3, -PI / 2, -PI / 2 + TAU * k, 28, Color(1, 1, 1, 0.8), 1.0)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		for i in charge_lv:
			var p := Vector2(-6 * (charge_lv - 1) / 2.0 + i * 6, -54)
			Ui.losango(self, p, 2.6, Ui.TINTA); Ui.losango(self, p, 1.8, c)
	if subiu_t > 0:
		var a := subiu_t / 90.0
		draw_rect(Rect2(-9, -60, 18, 60), Color(1, 0.85, 0.3, 0.22 * a))

func sync_node() -> void:
	position = Vector2(roundf(cx()), roundf(y + h))
	view.rotation = (-PI / 2 * clampf(dead_t / 20.0, 0, 1) * facing) if dead else 0.0
	view.visible = dead or not (invuln > 0 and state in ["idle", "run", "jump", "hurt"] and invuln % 6 < 3)
	_animar_boneco()
	if game and game.bg is Cenario3D:
		game.bg.sombra(self, cx(), y + h, 22.0)
		var lb: Vector4 = game.bg.luz_braseiro(cx(), y + h)
		view.boneco.luz_quente(Vector3(lb.x * facing, lb.y, lb.z), lb.w)
	queue_redraw()

## Traduz o estado do herói para a pose do boneco 3D.
func _animar_boneco() -> void:
	var b := view.boneco
	var dt := 1.0 / 60.0
	view.virado = facing
	b.vento = clampf(absf(vx) / 2.5, 0.0, 1.0)
	b.vy = -vy
	b.taxa_livre = 30.0
	if dead or state == "hurt":
		b.estado = "dor"
	elif game.result != null:
		b.estado = "livre"; b.alvo = POSE.vitoria; b.taxa_livre = 8.0
	elif state == "attack":
		var an = M.anim
		var hit: float = M.hit[0]
		if an is int:
			b.estado = "atk"; b.passo = an
			var dur: float = minf(M.dur, hit + 20.0)
			if state_t <= hit:
				b.t = state_t / hit * b.ACERTO[an]
			else:
				b.t = b.ACERTO[an] + minf(1.0, (state_t - hit) / maxf(1.0, dur - hit)) * (b.DUR[an] - b.ACERTO[an])
		else:
			b.estado = "livre"
			b.alvo = POSE[an[0]] if state_t < hit else POSE[an[1]]
			b.taxa_livre = 26.0 if state_t < hit else 55.0
	elif state == "charge":
		b.estado = "livre"; b.alvo = POSE.carga; b.taxa_livre = 14.0
	elif state == "skill":
		b.estado = "livre"; b.taxa_livre = 50.0
		if d.id == "guardiao":
			if skill == 0:
				b.alvo = POSE.escudo_pos
			elif skill == 1:
				b.alvo = POSE.lanca_pos if state_t > 3 else POSE.lanca_pre
			else:
				b.alvo = POSE.giro if state_t < 60 else POSE.lanca_pos
				if state_t < 60: view.virado = 1 if (state_t / 4) % 2 == 0 else -1
		elif d.id == "cacadora":
			var solta: int = [6, 9, 10][skill]
			if skill == 2: b.alvo = POSE.pilar_pre if state_t < solta else POSE.pilar_pos
			else: b.alvo = POSE.tiro_pre if state_t < solta else POSE.tiro_pos
		else:
			var solta2: int = [8, 10, 12][skill]
			if skill == 2: b.alvo = POSE.pilar_pre if state_t < solta2 else POSE.pilar_pos
			else: b.alvo = POSE.conjura_pre if state_t < solta2 else POSE.conjura_pos
	elif state == "dash":
		b.estado = "run"; dt *= 1.6
	elif not on_ground:
		b.estado = "ar"
	elif state == "run":
		b.estado = "run"
		if running: dt *= 1.35
	else:
		b.estado = "idle"
	view.animar(dt)
