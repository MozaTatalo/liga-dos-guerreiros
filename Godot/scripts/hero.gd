class_name Hero
extends Node2D
## Personagem jogável. Lê comandos de um PlayerInput, então vários heróis podem coexistir (multijogador).

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
var mp := 0.0
var state := "idle"
var state_t := 0
var step := 0
var queued := false
var jumps := 0
var invuln := 0
var cds := [0, 0, 0]
var dash_cd := 0
var skill := -1
var dead := false
var dead_t := 0
var anim := 0
var deny_t := 0
var view: HeroView   # boneco 3D (corpo base) desenhado no lugar da arte provisória

func setup(g, def: Dictionary, inp: PlayerInput, index := 0) -> void:
	game = g; d = def; input = inp; player_index = index
	x = 60.0 + index * 20.0
	y = GameData.GROUND - h
	hp = d.hp; mp = d.mp
	view = HeroView.new(d)
	add_child(view)

func cx() -> float:
	return x + w / 2.0

func front(ox: float, oy: float, bw: float, bh: float) -> Dictionary:
	return {"x": (x + w + ox) if facing > 0 else (x - ox - bw), "y": y + oy, "w": bw, "h": bh}

func follow(ox: float, oy: float, bw: float, bh: float) -> Callable:
	return func(o: Dictionary) -> void:
		o.merge(front(ox, oy, bw, bh), true)

func set_idle() -> void:
	state = "idle"; state_t = 0; skill = -1

func start_attack(s: int) -> void:
	state = "attack"; state_t = 0; step = s; queued = false
	if input.held("left"):
		facing = -1
	if input.held("right"):
		facing = 1

func tick() -> void:
	anim += 1
	mp = minf(d.mp, mp + 0.1)
	for i in 3:
		if cds[i] > 0:
			cds[i] -= 1
	if dash_cd > 0: dash_cd -= 1
	if invuln > 0: invuln -= 1
	if deny_t > 0: deny_t -= 1
	if dead:
		dead_t += 1; vx *= 0.92
		game.physics(self)
		return
	if game.result != null:
		vx *= 0.8
		game.physics(self)
		return
	state_t += 1
	var L := input.held("left")
	var R := input.held("right")
	match state:
		"hurt":
			vx *= 0.85
			if state_t > 18:
				set_idle()
		"attack":
			if on_ground:
				vx *= 0.75
			if state_t == GameData.ATK_HIT[step]:
				attack_hit()
			if input.tapped("attack") and state_t > 3:
				queued = true
			if state_t > GameData.ATK_HIT[step] and try_skills():
				pass
			elif state_t >= GameData.ATK_DUR[step]:
				if queued and step < 2:
					start_attack(step + 1)
				else:
					set_idle()
		"skill":
			if on_ground and not skill_moves(skill):
				vx *= 0.7
			skill_update(skill, state_t)
			if state == "skill" and state_t >= d.skills[skill].dur:
				set_idle()
		"dash":
			vx = 4.6 * facing
			if state_t % 2 == 1:
				game.ghost(self)
			if state_t > 12:
				set_idle(); vx = 1.5 * facing
		_:
			var tv := ((1.0 if R else 0.0) - (1.0 if L else 0.0)) * float(d.speed)
			vx += (tv - vx) * 0.3
			if L and not R: facing = -1
			if R and not L: facing = 1
			if not on_ground:
				state = "jump"
			elif absf(tv) > 0:
				state = "run"
			else:
				state = "idle"
			if input.tapped("jump"):
				if input.held("down") and on_ground and y + h < GameData.GROUND - 1:
					drop_t = 10; y += 1
				elif on_ground:
					vy = -6.2; jumps = 1
					game.dust(cx(), y + h)
				elif jumps < 2:
					vy = -5.4; jumps = 2
					game.sparks(cx(), y + h, "#ffffff", 5, 1.5)
			if input.tapped("attack"):
				start_attack(0)
			elif input.tapped("dash") and dash_cd <= 0:
				state = "dash"; state_t = 0; dash_cd = 40
				invuln = maxi(invuln, 14); vy = minf(vy, 0.0)
			else:
				try_skills()
	var was_air := not on_ground
	game.physics(self)
	if on_ground:
		jumps = 0
		if was_air and vy == 0.0:
			game.dust(cx(), y + h, 3)
	game.apply_barriers(self)

func try_skills() -> bool:
	var acts := ["skill1", "skill2", "skill3"]
	for i in 3:
		if not input.tapped(acts[i]):
			continue
		var sk: Dictionary = d.skills[i]
		if cds[i] > 0 or mp < sk.mp:
			deny_t = 20
			continue
		if input.held("left"): facing = -1
		if input.held("right"): facing = 1
		state = "skill"; skill = i; state_t = 0; mp -= sk.mp; cds[i] = sk.cd
		skill_start(i)
		game.callout(cx(), y - 14, sk.n + "!", sk.c)
		return true
	return false

# ---------------- Ataques básicos ----------------
func arrow(dmg: float, extra := {}) -> void:
	var o := {"owner": "p", "x": cx() + facing * 6 - 5, "y": y + 9, "w": 12.0, "h": 3.0, "vx": 6.5 * facing, "vy": 0.0,
		"dmg": dmg, "kbx": 2.0, "kby": 0.5, "life": 70, "kind": "arrow", "dir": facing}
	o.merge(extra, true)
	game.spawn_proj(o)

func attack_hit() -> void:
	var f := facing
	var big := step == 2
	var id: String = d.id
	var px := cx()
	var py := y + 12
	var s := step
	if id == "guardiao":
		if on_ground:
			vx = f * (2.5 if big else 1.5)
		var hb := {"owner": "p", "dmg": 20 if big else 11, "kbx": 4.5 if big else 1.5, "kby": 3.0 if big else 0.5, "life": 5, "heavy": big, "dir": f}
		hb.merge(front(-2, -6 if big else 2, 28 if big else 24, 28 if big else 18), true)
		game.spawn_hitbox(hb)
		var r := 22.0 if big else 18.0
		game.add_fx(9, func(c, k): Gfx.slash(c, px, py, f, r, s, k, "#ffffff"))
	elif id == "cacadora":
		if big:
			arrow(17, {"pierce": true, "w": 16.0, "kbx": 4.0, "kby": 1.5, "color": "#ffd23f"})
		else:
			arrow(9)
		if on_ground:
			vx = -f * (1.5 if big else 0.5)
	else:
		if not big:
			var hb2 := {"owner": "p", "dmg": 8, "kbx": 1.2, "kby": 0.3, "life": 5, "dir": f}
			hb2.merge(front(-2, 2, 20, 16), true)
			game.spawn_hitbox(hb2)
			game.add_fx(8, func(c, k): Gfx.slash(c, px, py, f, 15.0, s, k, "#59d0ff"))
		else:
			game.spawn_proj({"owner": "p", "x": px + f * 8 - 5, "y": y + 7, "w": 10.0, "h": 8.0, "vx": 4.5 * f, "vy": 0.0,
				"dmg": 18, "kbx": 3.0, "kby": 1.0, "life": 80, "kind": "bolt", "dir": f})

# ---------------- Habilidades ----------------
func skill_moves(i: int) -> bool:
	return d.id == "guardiao" or (d.id == "cacadora" and i == 1)

func skill_start(i: int) -> void:
	match d.id:
		"guardiao":
			if i == 0:
				invuln = maxi(invuln, 18)
				game.spawn_hitbox({"owner": "p", "dmg": 22, "kbx": 5.0, "kby": 2.0, "life": 15, "heavy": true, "dir": facing, "place": follow(-4, 0, 14, 24)})
			elif i == 1:
				var me := self
				game.spawn_hitbox({"owner": "p", "dmg": 11, "kbx": 2.0, "kby": 1.0, "life": 36, "rehit": 9, "dir": 0,
					"place": func(o: Dictionary) -> void:
						o.x = me.cx() - 30; o.y = me.y - 4; o.w = 60.0; o.h = 30.0})
			else:
				vy = -5.5; vx = 1.5 * facing
				game.spawn_hitbox({"owner": "p", "dmg": 28, "kbx": 1.5, "kby": 6.5, "life": 12, "heavy": true, "dir": facing, "place": follow(-4, -12, 22, 34)})
		"cacadora":
			if i == 1:
				vx = -3.5 * facing; vy = -4.5; invuln = maxi(invuln, 24)

func skill_update(i: int, t: int) -> void:
	var f := facing
	match d.id:
		"guardiao":
			if i == 0:
				vx = 5.0 * f if t < 14 else vx * 0.6
				if t % 2 == 1:
					game.ghost(self)
			elif i == 1:
				vx = ((1.0 if input.held("right") else 0.0) - (1.0 if input.held("left") else 0.0)) * 0.9
		"cacadora":
			if i == 0 and t == 6:
				for v in [-0.9, 0.0, 0.9]:
					arrow(13, {"vy": v})
			elif i == 1 and t == 8:
				arrow(30, {"pierce": true, "w": 18.0, "kbx": 4.0, "kby": 2.0, "color": "#ffd23f"})
			elif i == 2 and t == 8:
				var bx := x
				for n in 18:
					var off := randf_range(30, 210)
					game.timers.append({"t": 4 + n * 3, "fn": func():
						game.spawn_proj({"owner": "p", "x": bx + f * off, "y": -10.0, "w": 3.0, "h": 12.0, "vx": 0.6 * f, "vy": 7.5,
							"dmg": 10, "kbx": 0.5, "kby": 1.0, "life": 60, "kind": "rain", "dir": f})})
		"arcanista":
			if i == 0 and t == 8:
				game.spawn_proj({"owner": "p", "x": cx() + f * 8 - 6, "y": y + 5, "w": 12.0, "h": 12.0, "vx": 3.2 * f, "vy": 0.0,
					"dmg": 30, "kbx": 3.0, "kby": 2.0, "life": 120, "kind": "fire", "dir": f,
					"on_end": func(o): game.explode(o.x + 6, o.y + 6, 44, 40, 12, 2, "#ff8a3d")})
			elif i == 1 and t == 10:
				chain_lightning()
			elif i == 2 and t == 10:
				var sx := x - f * 60
				var sy := -40.0
				var tx := x + f * 130
				var N := 40.0
				game.spawn_proj({"owner": "p", "x": sx, "y": sy, "w": 18.0, "h": 18.0, "vx": (tx - sx) / N, "vy": (GameData.GROUND - 18 - sy) / N,
					"dmg": 20, "kbx": 2.0, "kby": 3.0, "life": 200, "pierce": true, "kind": "meteor", "dir": f,
					"on_end": func(o): game.explode(o.x + 9, GameData.GROUND - 20, 110, 64, 55, 5, "#ff4d2e")})

func chain_lightning() -> void:
	var c0 := cx()
	var c1 := y + 8
	var list := []
	for e in game.enemies:
		if e.hp > 0 and Vector2(e.x + e.w / 2 - c0, e.y + e.h / 2 - c1).length() < 240:
			list.append(e)
	list.sort_custom(func(a, b): return absf(a.x - c0) < absf(b.x - c0))
	list = list.slice(0, 4)
	var px := c0 + facing * 8
	var py := c1 - 6
	if list.is_empty():
		game.bolt(px, py, px + facing * 60, py + 20)
	for e in list:
		var ex: float = e.x + e.w / 2
		var ey: float = e.y + e.h / 2
		game.bolt(px, py, ex, ey)
		px = ex; py = ey
		game.damage_enemy(e, 32, 1 if ex > c0 else -1, 1.0, 3.0, true)
		game.sparks(ex, ey, "#9ff0ff", 10, 3)

# ---------------- Desenho ----------------
func _draw() -> void:
	if invuln > 0 and state != "skill" and state != "dash" and not dead and invuln % 6 < 3:
		return
	if state == "skill" and d.id == "guardiao" and skill == 1:
		draw_set_transform(Vector2(0, -12), 0.0, Vector2(1, 0.4))
		draw_arc(Vector2.ZERO, 30, state_t * 0.7, state_t * 0.7 + 4, 16, Gfx.col("#9fd3ff", 0.6), 2.0)
		draw_set_transform_matrix(Transform2D.IDENTITY)

func sync_node() -> void:
	position = Vector2(roundf(cx()), roundf(y + h))
	rotation = (-PI / 2 * clampf(dead_t / 20.0, 0, 1) * facing) if dead else 0.0
	view.visible = not (invuln > 0 and state != "skill" and state != "dash" and not dead and invuln % 6 < 3)
	_animar_boneco()
	queue_redraw()

## Traduz o estado do herói para a pose do boneco 3D.
func _animar_boneco() -> void:
	var b := view.boneco
	view.virado = facing
	b.vento = clampf(absf(vx) / 2.5, 0.0, 1.0)
	b.vy = -vy
	if dead or state == "hurt":
		b.estado = "dor"
	elif state == "attack":
		b.estado = "atk"; b.passo = step
		var hit: float = GameData.ATK_HIT[step]
		var dur: float = GameData.ATK_DUR[step]
		if state_t <= hit:
			b.t = state_t / hit * b.ACERTO[step]
		else:
			b.t = b.ACERTO[step] + (state_t - hit) / maxf(1.0, dur - hit) * (b.DUR[step] - b.ACERTO[step])
	elif state == "skill":
		var p := 2
		if d.id == "guardiao":
			p = [0, (state_t / 9) % 2, 2][skill]
		var sdur: float = d.skills[skill].dur
		b.estado = "atk"; b.passo = p
		var tt := float(state_t % 9) / 9.0 if (d.id == "guardiao" and skill == 1) else state_t / sdur
		b.t = tt * b.DUR[p]
	elif state == "dash":
		b.estado = "run"
	elif not on_ground:
		b.estado = "ar"
	elif state == "run":
		b.estado = "run"
	else:
		b.estado = "idle"
	view.animar(1.0 / 60.0)
