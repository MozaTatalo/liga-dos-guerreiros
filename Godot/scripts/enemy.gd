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
var esp: Espectro3D   # corpo 3D (espectro) dos inimigos que já vieram do teste gótico

func setup(g, k: String, px: float, s: int, plat_y = null) -> void:
	game = g; kind = k; sec = s; x = px
	var def: Dictionary = GameData.ENEMIES[k]
	w = def.w; h = def.h; hp = def.hp; maxhp = def.hp; dmg = def.dmg; fly = def.fly
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
	if Espectro3D.TIPOS.has(k) and g.bg is Cenario3D:
		esp = Espectro3D.new(k)
		g.bg.add_child(esp)

func tick() -> void:
	var p: Hero = game.nearest_player(x + w / 2)
	var dx: float = (p.cx() - (x + w / 2)) if p else 0.0
	var dy: float = ((p.y + p.h / 2) - (y + h / 2)) if p else 0.0
	var dist := absf(dx)
	var alive := p != null
	anim += 1
	if flash_t > 0: flash_t -= 1
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
					game.spawn_hitbox({"owner": "e", "dmg": 12, "kbx": 3.0, "kby": 2.0, "life": 6, "dir": dir,
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
						"dmg": 9, "kbx": 2.0, "kby": 1.0, "life": 160, "kind": "ebolt", "no_ground": true})
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
	match state:
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
				if dist > 150:
					state = "charge" if r < 0.5 else "rocks"
				else:
					state = "slam" if r < 0.45 else ("charge" if r < 0.75 else "rocks")
				t = 0
		"slam":
			if t < 20:
				vx = 0
			elif t == 20:
				vy = -7; vx = clampf(dx / 40.0, -3, 3); air = true
			elif on_ground and air and t > 24:
				air = false; game.shake = 9.0; game.dust(x + w / 2, GameData.GROUND, 14); vx = 0
				for s in [-1, 1]:
					game.spawn_proj({"owner": "e", "x": x + w / 2 - 5, "y": GameData.GROUND - 14, "w": 10.0, "h": 14.0, "vx": 3.3 * s * sp, "vy": 0.0,
						"dmg": 15, "kbx": 3.0, "kby": 4.0, "life": 80, "kind": "wave", "no_ground": true})
				state = "recover"; t = 0
		"charge":
			if t < 35:
				vx = 0
				if dx != 0: dir = 1 if dx > 0 else -1
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
				game.spawn_proj({"owner": "e", "x": x + w / 2 - 5, "y": y, "w": 10.0, "h": 10.0, "vx": clampf(ddx / 40.0, -5, 5), "vy": -6.0, "grav": 0.3,
					"dmg": 12, "kbx": 2.0, "kby": 2.0, "life": 200, "kind": "rock", "on_end": func(o): game.dust(o.x + 5, GameData.GROUND, 6)})
			if t > (66 if enr else 56):
				state = "recover"; t = 0
		"recover":
			vx *= 0.85
			if t > (28 if enr else 48):
				state = "idle"; t = 0

func contact_damage() -> float:
	return 20.0 if (boss and state == "charge") else dmg

# ---------------- Desenho ----------------
func _exit_tree() -> void:
	if is_instance_valid(esp):
		esp.morrer()

func _sync_esp() -> void:
	var PX := Cenario3D.PX
	esp.position = Vector3((x + w / 2) / PX, (GameData.GROUND - (y + h)) / PX, 0.0)
	esp.lado = dir
	esp.vx = vx
	esp.furia = boss and hp < maxhp * 0.5
	if flash_t > 0:
		esp.flash = 0.05
		esp.amasso = maxf(esp.amasso, 0.6)
	var prep := false
	match kind:
		"saqueador": prep = state == "windup"
		"atirador": prep = state == "aim"
		"boss": prep = (state == "charge" and t < 35) or (state == "slam" and t < 20)
	esp.preparo += ((1.0 if prep else 0.0) - esp.preparo) * 0.25
	esp.posar(1.0 / 60.0)

func _draw() -> void:
	if esp:
		_sync_esp()
		if not boss and hp < maxhp:
			Gfx.rect(self, roundf(x) - 1, roundf(y) - 14, w + 2, 3, "#000000")
			Gfx.rect(self, roundf(x), roundf(y) - 13, w * (hp / maxhp), 1, "#ff4d4d")
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
