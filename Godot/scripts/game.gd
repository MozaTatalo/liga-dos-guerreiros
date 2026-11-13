extends Node2D
## Uma partida (fase). Gerencia jogadores, inimigos, golpes, projéteis, câmera e regras da fase.

signal finished(to_title: bool, class_indexes: Array)

const WorldScript := preload("res://scripts/world.gd")
const FxScript := preload("res://scripts/fx_layer.gd")
const HudScript := preload("res://scripts/hud.gd")

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

var t := 0
var cam_x := 0.0
var combo := 0
var combo_t := 0
var max_combo := 0
var dmg_taken := 0
var kills := 0
var msg := ""
var msg_t := 0
var boss_started := false
var boss_dead := false
var cleared := [false, false]
var result = null
var hitstop := 0
var shake := 0.0
var paused := false
var all_dead_t := 0

var bg
var world
var fx_layer
var hud
var ent_layer: Node2D
var camera: Camera2D

## class_indexes: uma classe por jogador, ex.: [0] (solo) ou [0, 2] (dois jogadores)
func setup(indexes: Array, background) -> void:
	class_indexes = indexes
	bg = background
	world = WorldScript.new(); world.game = self; add_child(world)
	ent_layer = Node2D.new(); add_child(ent_layer)
	fx_layer = FxScript.new(); fx_layer.game = self; add_child(fx_layer)
	camera = Camera2D.new(); add_child(camera); camera.make_current()
	var hl := CanvasLayer.new(); add_child(hl)
	hud = HudScript.new(); hud.game = self; hl.add_child(hud)
	for i in indexes.size():
		var p := Hero.new()
		p.setup(self, GameData.CLASSES[indexes[i]], PlayerInput.new("p%d_" % (i + 1)), i)
		ent_layer.add_child(p)
		players.append(p)
	for i in GameData.SPAWNS.size():
		for s in GameData.SPAWNS[i]:
			add_enemy(s[0], s[1], i, s[2] if s.size() > 2 else null)
	show_msg("FASE 1 — Ruínas de Arvália", 170)

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
		e.vy = minf(e.vy + 0.3, 8.0)
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
	add_fx(50, func(cv, k): Gfx.text(cv, text, px, py - k * 10, c, 9, 1, 1.0 if k < 0.8 else (1 - k) * 5))

func sparks(px: float, py: float, c, n: int, sp := 2.5) -> void:
	for i in n:
		var a := randf_range(0, TAU)
		var s := randf_range(0.5, sp)
		parts.append({"x": px, "y": py, "vx": cos(a) * s, "vy": sin(a) * s - 0.5, "life": randf_range(14, 26), "c": c, "s": randf_range(1, 2.5), "g": 0.1})

func dust(px: float, py: float, n := 4) -> void:
	for i in n:
		parts.append({"x": px + randf_range(-4, 4), "y": py, "vx": randf_range(-1, 1), "vy": randf_range(-1, -0.2), "life": randf_range(12, 22), "c": "#b9a888", "s": 2.0, "g": 0.0})

func ghost(p: Hero) -> void:
	parts.append({"x": p.cx(), "y": p.y + 12, "vx": 0.0, "vy": 0.0, "life": 10.0, "c": p.d.body, "s": 7.0, "g": 0.0, "a": 0.35})

func num(px: float, py: float, v, c, big := false) -> void:
	nums.append({"x": px, "y": py, "v": str(v), "c": c, "big": big, "t": 0})

func hit(target, src: Dictionary, cxv: float) -> void:
	var dir := int(src.get("dir", 0))
	if dir == 0:
		dir = 1 if target.x + target.w / 2 >= cxv else -1
	if target is Hero:
		hurt_player(target, src.dmg, dir, src.get("kbx", 2.0), src.get("kby", 2.0))
	else:
		damage_enemy(target, src.dmg, dir, src.get("kbx", 1.0), src.get("kby", 0.0), src.get("heavy", false))

func damage_enemy(e: Enemy, dmg: float, dir: int, kbx: float, kby: float, heavy := false) -> void:
	if e.hp <= 0:
		return
	var crit := randf() < 0.1
	var amount := int(roundf(dmg * randf_range(0.9, 1.1) * (1.5 if crit else 1.0)))
	e.hp -= amount; e.flash_t = 6; e.active = true
	if e.boss:
		e.vx += dir * kbx * 0.12
	else:
		e.vx = dir * kbx
		if kby > 0:
			e.vy = -kby; e.on_ground = false
		e.hurt_t = 30 if heavy else 16
		e.state = "walk"; e.t = 0
	num(e.x + e.w / 2, e.y - 4, amount, "#ffd23f" if crit else "#ffffff", crit)
	sparks(e.x + e.w / 2 - dir * 4, e.y + e.h / 2, "#ffd23f" if crit else "#fff3c4", 10 if crit else 6)
	hitstop = maxi(hitstop, 6 if heavy else 3)
	if heavy or crit: shake = maxf(shake, 4)
	combo += 1; combo_t = 120; max_combo = maxi(max_combo, combo)
	for p in players:
		p.mp = minf(p.d.mp, p.mp + 1.5)
	if e.hp <= 0:
		kill_enemy(e)

func kill_enemy(e: Enemy) -> void:
	e.hp = 0; kills += 1
	var ex := e.x + e.w / 2
	var ey := e.y + e.h / 2
	var c: String = {"lodo": "#6fd36b", "saqueador": "#b5651d", "morcego": "#7a5ca8", "atirador": "#8a8f9c", "boss": "#d9a066"}[e.kind]
	sparks(ex, ey, c, 60 if e.boss else 16, 5 if e.boss else 3)
	sparks(ex, ey, "#ffffff", 30 if e.boss else 6, 3)
	if e.boss:
		boss_dead = true; shake = 14; hitstop = 20
		show_msg("Espectro Ancião derrotado! Siga para o portal »", 220)
		for i in 6:
			timers.append({"t": i * 8, "fn": func(): sparks(ex + randf_range(-20, 20), ey + randf_range(-20, 20), "#ffb347", 20, 4)})
	elif randf() < 0.3:
		pickups.append({"x": ex - 4, "y": e.y, "w": 8.0, "h": 8.0, "vy": -2.0, "kind": "hp" if randf() < 0.55 else "mp", "t": 0})

func hurt_player(p: Hero, dmg: float, dir: int, kbx := 2.0, kby := 2.0) -> void:
	if p.invuln > 0 or p.dead or result != null:
		return
	p.hp -= dmg; dmg_taken += int(dmg)
	num(p.cx(), p.y - 4, int(dmg), "#ff5b5b")
	sparks(p.cx(), p.y + 10, "#ff5b5b", 8)
	shake = maxf(shake, 5); hitstop = maxi(hitstop, 4); combo = 0
	if p.hp <= 0:
		p.hp = 0; p.dead = true; p.state = "dead"; p.vx = dir * 2; p.vy = -3
		return
	p.state = "hurt"; p.state_t = 0; p.vx = dir * kbx; p.vy = -kby; p.invuln = 60; p.skill = -1

func explode(px: float, py: float, w: float, h: float, dmg: float, kby: float, c: String) -> void:
	spawn_hitbox({"owner": "p", "x": px - w / 2, "y": py - h / 2, "w": w, "h": h, "dmg": dmg, "kbx": 3.0, "kby": kby, "life": 6, "heavy": true})
	shake = maxf(shake, 6)
	sparks(px, py, c, 26, 4); sparks(px, py, "#fff6d0", 10, 3)
	add_fx(16, func(cv, k): cv.draw_circle(Vector2(px, py), (w / 2) * (0.4 + k * 0.8), Gfx.col(c, 1 - k)))

func bolt(x1: float, y1: float, x2: float, y2: float) -> void:
	var pts := PackedVector2Array()
	for i in 9:
		var k := i / 8.0
		var j := 0.0 if (i == 0 or i == 8) else 1.0
		pts.append(Vector2(x1 + (x2 - x1) * k + randf_range(-6, 6) * j, y1 + (y2 - y1) * k + randf_range(-6, 6) * j))
	add_fx(14, func(cv, k):
		cv.draw_polyline(pts, Gfx.col("#59d0ff", (1 - k) * 0.4), 4.0)
		cv.draw_polyline(pts, Gfx.col("#e6fdff", 1 - k), 2.0))

# ---------------- Laço principal (60 passos fixos por segundo) ----------------
func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause") and result == null:
		paused = not paused
	if not paused:
		step()
	redraw()

func step() -> void:
	var everyone_dead := alive_players().is_empty()
	if everyone_dead:
		all_dead_t += 1
		if all_dead_t > 60:
			if Input.is_action_just_pressed("restart"):
				finished.emit(false, class_indexes); return
			if Input.is_action_just_pressed("confirm"):
				finished.emit(true, class_indexes); return
	if result != null:
		if Input.is_action_just_pressed("restart"):
			finished.emit(false, class_indexes); return
		if Input.is_action_just_pressed("confirm"):
			finished.emit(true, class_indexes); return
	if hitstop > 0:
		hitstop -= 1
		return
	if result == null and not everyone_dead:
		t += 1
	for p in players:
		p.tick()
	var lead := nearest_player(0) # quem está mais à frente define gatilhos
	for p in alive_players():
		if p.x > lead.x: lead = p
	if lead and not boss_started and sec_cleared(1) and lead.x > GameData.BOSS_TRIGGER_X:
		boss_started = true
		var b := add_enemy("boss", 2660, 2)
		b.y = -80; b.state = "intro"; b.active = true
		show_msg("O Espectro Ancião despertou!", 150)
	for e in enemies:
		if e.hp > 0: e.tick()
	# dano por contato
	for p in alive_players():
		for e in enemies:
			if e.hp > 0 and e.hurt_t <= 0 and e.state != "intro" and overlap(e, p):
				hurt_player(p, e.contact_damage(), 1 if p.x >= e.x else -1, 2.5, 2.5)
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
		if not o.get("no_ground", false) and o.y + o.h >= GameData.GROUND: o.dead = true
		if o.t > o.life or o.x < -50 or o.x > GameData.LEVEL_W + 50: o.dead = true
		if o.kind == "fire" and o.t % 2 == 1:
			parts.append({"x": o.x + 6, "y": o.y + 6, "vx": randf_range(-0.3, 0.3), "vy": randf_range(-0.6, 0), "life": 14.0, "c": "#ff8a3d" if randf() < 0.5 else "#ffd23f", "s": 3.0, "g": 0.0})
		if o.kind == "meteor":
			for i in 2:
				parts.append({"x": o.x + 9, "y": o.y + 9, "vx": randf_range(-0.5, 0.5), "vy": randf_range(-0.5, 0.5), "life": 20.0, "c": "#ff4d2e" if randf() < 0.5 else "#ffb347", "s": 4.0, "g": 0.0})
		if o.get("dead", false) and o.has("on_end"):
			o.on_end.call(o)
	projs = projs.filter(func(o): return not o.get("dead", false))
	for e in enemies:
		if e.hp <= 0: e.queue_free()
	enemies = enemies.filter(func(e): return e.hp > 0)
	for i in 2:
		if not cleared[i] and sec_cleared(i):
			cleared[i] = true
			show_msg("Área liberada! Avance »" if i == 0 else "Caminho para a arena liberado »", 150)
	# timers, itens, partículas
	for tm in timers:
		tm.t -= 1
		if tm.t <= 0:
			tm.fn.call(); tm.done = true
	timers = timers.filter(func(tm): return not tm.get("done", false))
	for k in pickups:
		k.t += 1; k.vy = minf(k.vy + 0.2, 4); k.y += k.vy
		if k.y + k.h > GameData.GROUND:
			k.y = GameData.GROUND - k.h; k.vy = 0.0
		for p in alive_players():
			if k.t > 15 and not k.get("dead", false) and overlap(k, p):
				k.dead = true
				if k.kind == "hp":
					p.hp = minf(p.d.hp, p.hp + 30); num(p.x + 6, p.y - 6, "+30", "#7dff8a")
				else:
					p.mp = minf(p.d.mp, p.mp + 40); num(p.x + 6, p.y - 6, "+40", "#7db8ff")
	pickups = pickups.filter(func(k): return not k.get("dead", false) and k.t < 900)
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
				var time := t / 60.0
				var rank := "C"
				if time < 150 and dmg_taken < 60: rank = "S"
				elif time < 240 and dmg_taken < 150: rank = "A"
				elif dmg_taken < 300: rank = "B"
				result = {"time": time, "dt": dmg_taken, "rank": rank}
				break
	update_camera()
	if shake > 0:
		shake *= 0.85
		if shake < 0.3: shake = 0.0

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
	var off := Vector2(randf_range(-shake, shake), randf_range(-shake, shake)) if shake > 0 else Vector2.ZERO
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
