class_name Enemy
extends Node2D
## Inimigos comuns e o chefe. A IA mira o jogador vivo mais próximo (pronto para multijogador).

var game
var kind := ""
var x := 0.0
var y := 0.0
var w := 0.0
var h := 0.0
var vx := 0.0
var vy := 0.0
var hp := 0.0
var maxhp := 0.0
var dmg := 0.0
var fly := false
var dir := -1
var state := "walk"
var t := 0
var hurt_t := 0
var flash_t := 0
var atk_cd := 60
var on_ground := false
var drop_t := 0
var active := false
var sec := 0
var boss := false
var still := false
var anim := 0.0
var air := false
var landed := false
var imune := 0          # passos sem poder ser atingido (ao levantar)
var juggle := 0         # golpes levados no ar; cada um levanta menos
var otg := 0            # vezes que foi relançado do chão
var quicou := false
var tombo := 0.0        # inclinação do corpo 3D (lançado, caído)
var peso := 1.0
var postura := 100.0    # só o chefe: golpes pesados gastam; em zero ele fica atordoado
var esp: Inimigo3D   # corpo 3D do inimigo (espectro, lodo ou morcego), vive no Cenario3D

func setup(g, k: String, px: float, s: int, plat_y = null) -> void:
	game = g; kind = k; sec = s; x = px
	var def: Dictionary = GameData.ENEMIES[k]
	w = def.w; h = def.h; dmg = def.dmg; fly = def.fly; peso = def.peso
	hp = roundf(def.hp * g.D.vida); maxhp = hp
	boss = k == "boss"
	still = plat_y != null
	if plat_y != null:
		y = float(plat_y) - h
	elif fly:
		y = GameData.GROUND - 85
	else:
		y = GameData.GROUND - h
	t = randi_range(0, 59)
	anim = randf_range(0, 100)
	if g.bg is Cenario3D:
		if Espectro3D.TIPOS.has(k): esp = Espectro3D.new(k)
		elif k == "lodo": esp = Lodo3D.new()
		elif k == "morcego": esp = Morcego3D.new()
		if esp: g.bg.add_child(esp)

func tick() -> void:
	var p: Hero = game.nearest_player(x + w / 2)
	var dx: float = (p.cx() - (x + w / 2)) if p else 0.0
	var dy: float = ((p.y + p.h / 2) - (y + h / 2)) if p else 0.0
	var dist := absf(dx)
	var alive := p != null
	anim += 1
	if flash_t > 0: flash_t -= 1
	if imune > 0: imune -= 1
	if state == "launched":
		t += 1
		var queda := vy
		game.physics(self)
		vx *= 0.985
		game.apply_barriers(self)
		if on_ground and t > 2:
			game.dust(x + w / 2, y + h, 5)
			if not quicou and queda > 4.2:
				quicou = true; vy = -queda * 0.42; on_ground = false
				Som.tocar("queda", 0.7)
			else:
				state = "down"; t = 0; vx *= 0.4
				Som.tocar("queda", 0.5, 0.8)
		return
	if state == "down":
		t += 1; vx *= 0.8
		game.physics(self)
		game.apply_barriers(self)
		if t > 44:
			state = "walk"; t = 0; imune = 14; atk_cd = maxi(atk_cd, 36); juggle = 0; otg = 0; quicou = false; hurt_t = 0
			if fly: vy = -2.0
		return
	if not active:
		if alive and dist < 260:
			active = true
		else:
			if not fly: game.physics(self)
			return
	t += 1
	if hurt_t > 0:
		hurt_t -= 1; vx *= 0.9
		if fly:
			vy *= 0.9; x += vx; y = minf(y + vy, GameData.GROUND - h)
		else:
			game.physics(self)
		game.apply_barriers(self)
		return
	if atk_cd > 0: atk_cd -= 1
	match kind:
		"lodo":
			if on_ground:
				vx *= 0.75
				if t % 70 == 0 and alive:
					dir = 1 if dx >= 0 else -1
					vx = 1.7 * dir; vy = -4.2
		"saqueador":
			if state == "windup":
				vx = 0
				if t >= 22:
					game.spawn_hitbox({"owner": "e", "de": self, "dmg": 12, "kbx": 3.0, "kby": 2.0, "life": 6, "dir": dir,
						"x": (x + w) if dir > 0 else (x - 24), "y": y + 8, "w": 24.0, "h": 8.0})
					state = "recover"; t = 0
			elif state == "recover":
				vx = 0
				if t > 30:
					state = "walk"; t = 0
			else:
				if dx != 0: dir = 1 if dx > 0 else -1
				vx = 0.8 * dir if alive else 0.0
				if dist < 30 and absf(dy) < 20 and atk_cd <= 0 and alive:
					state = "windup"; t = 0; atk_cd = 70
		"morcego":
			vx = clampf(vx + signf(dx) * 0.07, -1.6, 1.6)
			vy = clampf(vy + signf(dy - 12) * 0.05 + sin(t * 0.12) * 0.06, -1.3, 1.3)
			dir = 1 if vx >= 0 else -1
			x += vx; y = clampf(y + vy, 30, GameData.GROUND - h)
			game.apply_barriers(self)
			return
		"atirador":
			if dx != 0: dir = 1 if dx > 0 else -1
			if state == "aim":
				vx = 0
				if t >= 24:
					game.spawn_proj({"owner": "e", "x": x + w / 2 + dir * 6, "y": y + 9, "w": 9.0, "h": 3.0, "vx": 2.8 * dir, "vy": 0.0,
						"dmg": 9, "kbx": 2.0, "kby": 1.0, "life": 160, "kind": "ebolt", "no_ground": true, "de": self})
					state = "walk"; t = 0; atk_cd = 110
			else:
				if still:
					vx = 0
				else:
					vx = -0.7 * dir if dist < 100 else (0.6 * dir if dist > 170 else 0.0)
				if dist < 250 and atk_cd <= 0 and alive and absf(dy) < 80:
					state = "aim"; t = 0
		"boss":
			boss_ai(p, dx, dist)
	game.physics(self, not fly)
	game.apply_barriers(self)

func boss_ai(p, dx: float, dist: float) -> void:
	var enr := hp < maxhp * 0.5
	var sp := 1.3 if enr else 1.0
	var meio := x + w / 2
	if state != "quebrado": postura = minf(100.0, postura + 0.035)
	match state:
		"quebrado":
			vx *= 0.8
			if t % 20 == 0: game.sparks(meio, y + 6, "#ffe9a8", 4, 1.5)
			if t > 210:
				postura = 100.0; state = "idle"; t = 0
		"pilares":
			vx = 0
			if (t == 12 or t == 38 or t == 64) and p:
				var tx: float = clampf(p.cx() + p.vx * 14.0, GameData.ARENA_L + 20, GameData.ARENA_R - 20)
				game.aviso(tx, 40.0, 40)
				var g = game
				var eu := self
				g.timers.append({"t": 40, "fn": func():
					if g.boss_dead or not is_instance_valid(eu): return
					g.spawn_hitbox({"owner": "e", "de": eu, "dmg": 16, "kbx": 1.5, "kby": 5.5, "life": 8, "x": tx - 15, "y": GameData.GROUND - 78, "w": 30.0, "h": 78.0})
					g.add_fx(20, func(cv, k):
						var a: float = 1.0 - k
						var alt: float = 84.0 * minf(1.0, k * 5.0)
						cv.draw_rect(Rect2(tx - 15 * a, GameData.GROUND - alt, 30 * a, alt), Color(0.62, 0.3, 1.0, 0.5 * a))
						cv.draw_rect(Rect2(tx - 7 * a, GameData.GROUND - alt, 14 * a, alt), Color(0.95, 0.85, 1.0, 0.85 * a)))
					g.sparks(tx, GameData.GROUND - 20, "#b58cff", 14, 4); g.dust(tx, GameData.GROUND, 6)
					if g.tremor_ligado(): g.shake = maxf(g.shake, 4)
					Som.tocar("explosao", 0.7, 1.5)})
			if t > 110:
				state = "recover"; t = 0
		"intro":
			vx = 0
			if on_ground and not landed:
				landed = true; game.shake = 12.0; game.dust(x + w / 2, GameData.GROUND, 14)
			if landed and t > 70:
				state = "idle"; t = 0
		"idle":
			if dx != 0: dir = 1 if dx > 0 else -1
			vx = 0.5 * dir * sp
			if t > (40 if enr else 70):
				var r := randf()
				if enr and r < 0.28:
					state = "pilares"
				elif dist > 150:
					state = "charge" if r < 0.6 else "rocks"
				else:
					state = "slam" if r < 0.5 else ("charge" if r < 0.8 else "rocks")
				t = 0
		"slam":
			if t < 20:
				vx = 0
			elif t == 20:
				vy = -7; vx = clampf(dx / 40.0, -3, 3); air = true
				game.aviso(clampf(meio + vx * 46.0, GameData.ARENA_L + 20, GameData.ARENA_R - 20), 76.0, 46)
			elif on_ground and air and t > 24:
				air = false; game.shake = 9.0; game.dust(x + w / 2, GameData.GROUND, 14); vx = 0
				for s in [-1, 1]:
					game.spawn_proj({"owner": "e", "x": x + w / 2 - 5, "y": GameData.GROUND - 14, "w": 10.0, "h": 14.0, "vx": 3.3 * s * sp, "vy": 0.0,
						"dmg": 15, "kbx": 3.0, "kby": 4.0, "life": 80, "kind": "wave", "no_ground": true, "de": self})
				state = "recover"; t = 0
		"charge":
			if t < 35:
				vx = 0
				if dx != 0: dir = 1 if dx > 0 else -1
				if t == 6:
					var borda := GameData.ARENA_R if dir > 0 else GameData.ARENA_L
					game.aviso((meio + borda) / 2.0, absf(borda - meio), 30, true)
			elif t < 100:
				vx = 4.3 * dir * sp
				if t % 3 == 0: game.dust(x + w / 2, GameData.GROUND, 2)
				if t > 40 and (x <= GameData.ARENA_L + 1 or x + w >= GameData.ARENA_R - 1):
					game.shake = 8.0; vx = -dir * 2; vy = -2; state = "recover"; t = 0
			else:
				state = "recover"; t = 0
		"rocks":
			vx = 0
			if (t == 20 or t == 36 or (enr and t == 52)) and p:
				var ddx: float = p.cx() - (x + w / 2) + randf_range(-20, 20)
				# onde a pedra vai cair
				var py := y; var pvy := -6.0; var n := 0
				while py + 10 < GameData.GROUND and n < 200:
					pvy += 0.3; py += pvy; n += 1
				game.aviso(meio + clampf(ddx / 40.0, -5, 5) * n, 26.0, n)
				game.spawn_proj({"owner": "e", "x": x + w / 2 - 5, "y": y, "w": 10.0, "h": 10.0, "vx": clampf(ddx / 40.0, -5, 5), "vy": -6.0, "grav": 0.3,
					"dmg": 12, "kbx": 2.0, "kby": 2.0, "life": 200, "kind": "rock", "de": self, "on_end": func(o): game.dust(o.x + 5, GameData.GROUND, 6)})
			if t > (66 if enr else 56):
				state = "recover"; t = 0
		"recover":
			vx *= 0.85
			if t > (28 if enr else 48):
				state = "idle"; t = 0

## Reação a um golpe do jogador: atordoa, lança para o ar, mantém no ar (juggle) ou crava no chão.
func apanhar(src: Dictionary, lado: int, pesado: bool) -> void:
	var lanca: float = src.get("launch", 0.0)
	var kbx: float = src.get("kbx", 1.0)
	if boss:
		vx += lado * kbx * 0.1
		if state != "quebrado" and state != "intro":
			perder_postura((7.0 if pesado else 2.2) * float(src.get("postura", 1.0)))
		return
	if state == "down":
		if lanca >= 4.0 and otg < 1:
			otg += 1; state = "launched"; t = 0; quicou = true
			vy = -lanca * 0.6 / peso; vx = lado * kbx * 0.5; on_ground = false
		else:
			vx = lado * kbx * 0.4
		return
	if state == "launched":
		juggle += 1
		var k := maxf(0.3, 1.0 - juggle * 0.07)
		if lanca < 0:
			vy = -lanca; quicou = false
		else:
			vy = -maxf(lanca, 2.7) * k / peso
		vx = lado * kbx * 0.7
		on_ground = false; t = 0
		return
	if lanca >= 3.0 or (fly and pesado):
		state = "launched"; t = 0; juggle = 0; otg = 0; quicou = false
		vy = -maxf(lanca, 3.0) / peso; vx = lado * kbx; on_ground = false
		return
	vx = lado * kbx
	if lanca > 0:
		vy = -lanca; on_ground = false
	hurt_t = 30 if pesado else 18
	state = "walk"; t = 0

## Quebra de postura do chefe: fica atordoado e leva mais dano por alguns segundos.
func perder_postura(n: float) -> void:
	if state == "quebrado" or state == "intro": return
	postura -= n
	if postura > 0: return
	postura = 0.0; state = "quebrado"; t = 0; vx = 0.0; air = false
	game.hitstop = maxi(game.hitstop, 14)
	if game.tremor_ligado(): game.shake = maxf(game.shake, 8)
	game.callout(x + w / 2, y - 12, "POSTURA QUEBRADA!", "#ffe9a8")
	game.anel(x + w / 2, y + h / 2, "#ffe9a8", 60.0)
	game.sparks(x + w / 2, y + h / 2, "#ffe9a8", 30, 5)
	Som.tocar("critico", 1.0, 0.7); Som.tocar("queda", 0.9, 0.7)

## Só alguns inimigos machucam ao encostar (os que atacam com o corpo).
func toca() -> bool:
	if state == "launched" or state == "down" or state == "intro" or imune > 0:
		return false
	match kind:
		"lodo": return not on_ground
		"morcego": return true
		"boss": return state != "recover" and state != "quebrado"
	return false

func contact_damage() -> float:
	return 20.0 if (boss and state == "charge") else dmg

# ---------------- Desenho ----------------
func _exit_tree() -> void:
	if is_instance_valid(esp):
		esp.morrer()
	if game and game.bg is Cenario3D:
		game.bg.sombra(self, 0, 0, 0, false)

func _sync_esp() -> void:
	var PX := Cenario3D.PX
	var pe_y := (y + h / 2) if fly else (y + h)
	esp.position = Vector3((x + w / 2) / PX, (GameData.GROUND - pe_y) / PX, 0.0)
	esp.lado = dir
	esp.vx = vx
	esp.vy = vy
	esp.no_chao = on_ground
	game.bg.sombra(self, x + w / 2, y + h, w * (3.2 if boss else 1.7))
	esp.furia = boss and hp < maxhp * 0.5
	if flash_t > 0:
		esp.flash = 0.05
		esp.amasso = maxf(esp.amasso, 0.6)
	var prep := false
	match kind:
		"saqueador": prep = state == "windup"
		"atirador": prep = state == "aim"
		"morcego": prep = state == "dive" or state == "swoop"
		"boss": prep = (state == "charge" and t < 35) or (state == "slam" and t < 20)
	esp.preparo += ((1.0 if prep else 0.0) - esp.preparo) * 0.25
	var alvo_t := 0.0
	if state == "launched": alvo_t = clampf(0.5 + t * 0.06, 0.5, 1.25)
	elif state == "down": alvo_t = 1.5
	elif state == "quebrado": alvo_t = 0.32 + sin(t * 0.08) * 0.04
	tombo += (alvo_t - tombo) * 0.3
	esp.posar(1.0 / 60.0)
	esp.rotation.z = tombo

func _draw() -> void:
	if esp:
		_sync_esp()
		if not boss and hp < maxhp:
			var bw := maxf(w + 4, 18.0)
			var bx := roundf(x + w / 2 - bw / 2)
			Gfx.rect(self, bx - 0.6, roundf(y) - 14.6, bw + 1.2, 3.2, "#0b0914", 0.9)
			Gfx.rect(self, bx, roundf(y) - 14, bw * (hp / maxhp), 2, "#e0413a")
			Gfx.rect(self, bx, roundf(y) - 14, bw * (hp / maxhp), 0.7, "#ff9a8a")
		return
	var fl := flash_t > 0
	var R := func(a, b, c, e, col): Gfx.rect(self, a, b, c, e, "#ffffff" if fl else col)
	var X := roundf(x)
	var Y := roundf(y)
	match kind:
		"lodo":
			var sq := 0 if on_ground else 2
			Gfx.rect(self, X, Y + sq, w, h - sq, "#ffffff" if fl else "#3f8f8a")
			Gfx.rect(self, X + 1, Y - 1 + sq, w - 2, 1, "#ffffff" if fl else "#3f8f8a")
			Gfx.rect(self, X + 2, Y + 2 + sq, w - 4, 2, "#ffffff" if fl else "#8fe8e0")
			Gfx.rect(self, X + (8 if dir > 0 else 3), Y + 4, 2, 2, "#112233")
			Gfx.rect(self, X + (11 if dir > 0 else 1), Y + 4, 2, 2, "#112233")
		"saqueador":
			draw_set_transform(Vector2(X + w / 2, Y + h), 0.0, Vector2(dir, 1))
			var lg := int(roundf(sin(anim * 0.25) * 2))
			Gfx.rect(self, -4 + lg, -7, 3, 7, "#3a2a1a"); Gfx.rect(self, 1 - lg, -7, 3, 7, "#3a2a1a")
			R.call(-5, -16, 10, 10, "#8a5a2b"); R.call(-4, -22, 8, 7, "#d6a77a")
			Gfx.rect(self, -5, -23, 9, 3, "#b3262c"); Gfx.rect(self, -6, -22, 2, 4, "#b3262c"); Gfx.rect(self, 2, -20, 1, 2, "#000000")
			var wind := state == "windup"
			var sx := -4 if wind else (8 if (state == "recover" and t < 8) else 2)
			Gfx.rect(self, sx, -13, 18, 1, "#7a5a3a"); Gfx.rect(self, sx + 18, -14, 4, 3, "#cfd6e0")
			if wind and t % 6 < 3:
				Gfx.rect(self, -6, -24, 12, 1, "#ff5050")
		"morcego":
			var fw := sin(anim * 0.4) * 4
			var c := "#ffffff" if fl else "#2a2238"
			Gfx.rect(self, X + 3, Y + 1, 6, 6, c)
			Gfx.tri(self, Vector2(X + 3, Y + 3), Vector2(X - 5, Y + 3 - fw), Vector2(X + 1, Y + 6), c)
			Gfx.tri(self, Vector2(X + 9, Y + 3), Vector2(X + 17, Y + 3 - fw), Vector2(X + 11, Y + 6), c)
			Gfx.rect(self, X + 4, Y + 3, 1, 1, "#ff5050"); Gfx.rect(self, X + 7, Y + 3, 1, 1, "#ff5050")
		"atirador":
			draw_set_transform(Vector2(X + w / 2, Y + h), 0.0, Vector2(dir, 1))
			Gfx.rect(self, -4, -7, 3, 7, "#2a2a33"); Gfx.rect(self, 1, -7, 3, 7, "#2a2a33")
			R.call(-5, -17, 10, 11, "#5d6270"); R.call(-5, -24, 9, 8, "#3d414b")
			Gfx.rect(self, -2, -21, 5, 4, "#1b1d22"); Gfx.rect(self, 1, -20, 2, 1, "#ffcf4a")
			Gfx.rect(self, 3, -14, 9, 2, "#6b4a2b"); Gfx.rect(self, 10, -17, 2, 8, "#6b4a2b")
			if state == "aim" and t % 6 < 3:
				Gfx.rect(self, 12, -14, 2, 2, "#ff5050")
		"boss":
			var wind2 := (state == "charge" and t < 35) or (state == "slam" and t < 20)
			var shk := 1 if (wind2 and t % 4 < 2) else 0
			draw_set_transform(Vector2(X + w / 2 + shk, Y + h), 0.0, Vector2(dir, 1))
			var c1 := "#8c7a66"
			var c2 := "#5e5246"
			R.call(-15, -14, 10, 14, c2); R.call(5, -14, 10, 14, c2); R.call(-18, -42, 36, 30, c1); R.call(-14, -52, 22, 12, c1)
			R.call(-18, -42, 36, 3, c2); R.call(-22, -40, 7, 22, c2); R.call(16, -40, 8, 22, c2); R.call(-24, -20, 9, 9, c1); R.call(16, -20, 10, 9, c1)
			var eye := "#ff3b2e" if hp < maxhp * 0.5 else "#ffb347"
			Gfx.rect(self, 2, -48, 4, 3, eye); Gfx.rect(self, -6, -48, 4, 3, eye); Gfx.rect(self, -4, -32, 8, 8, eye); Gfx.rect(self, -2, -30, 4, 4, "#fff3c4")
			for i in 4:
				Gfx.rect(self, -16 + i * 9, -39 + ((i * 7) % 5), 3, 2, "#6e6153")
			if wind2:
				Gfx.rect(self, -20, -54, 42, 56, "#ff5030", 0.35 + 0.25 * sin(t * 0.6))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if not boss and hp < maxhp:
		Gfx.rect(self, X - 1, Y - 6, w + 2, 3, "#000000")
		Gfx.rect(self, X, Y - 5, w * (hp / maxhp), 1, "#ff4d4d")
