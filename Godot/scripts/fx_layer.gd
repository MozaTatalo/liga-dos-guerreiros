extends Node2D
## Projéteis, itens, partículas, efeitos e números de dano.
## Tudo que brilha é desenhado num nó com mistura aditiva (luz somando, no estilo dos jogos de ação anime).

var game
var luz: Node2D
var eco: Node2D     # imagens fantasma dos heróis (silhueta de luz colorida)
var energia: Node2D # cortes, ondas, pilares e fogo: luz somada com borda que se desfaz (shader energia)
var _carga_ant := {}  # nível de carga de cada herói no passo anterior, para estourar o efeito ao subir de nível

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	luz = Node2D.new()
	var m := CanvasItemMaterial.new(); m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	luz.material = m
	luz.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	luz.draw.connect(_draw_luz)
	eco = Node2D.new()
	var me := ShaderMaterial.new(); me.shader = preload("res://shaders/fantasma.gdshader")
	eco.material = me
	eco.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	eco.draw.connect(_draw_eco)
	energia = Node2D.new()
	var men := ShaderMaterial.new(); men.shader = preload("res://shaders/energia.gdshader")
	men.set_shader_parameter("ruido", Efeitos.tex_ruido())
	energia.material = men
	energia.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	energia.draw.connect(_draw_energia)
	add_child(eco)
	add_child(energia)
	add_child(luz)

func _process(_d: float) -> void:
	luz.queue_redraw()
	eco.queue_redraw()
	energia.queue_redraw()

func _draw_eco() -> void:
	for f in game.fantasmas:
		var k: float = float(f.t) / f.vida
		var c: Color = f.c
		eco.draw_texture_rect(f.tex, Rect2(f.pos.x - f.tam / 2.0, f.pos.y - f.alt / 2.0, f.tam, f.alt), false, Color(c.r, c.g, c.b, 0.55 * (1.0 - k)))

func _draw() -> void:
	for k in game.pickups:
		var b := sin(k.t * 0.15) * 1.5
		if k.kind == "ouro":
			var pm := Vector2(k.x + 3, k.y + 3)
			var lg := absf(cos(k.t * 0.2)) * 2.4 + 0.6
			draw_colored_polygon(PackedVector2Array([pm + Vector2(0, -3), pm + Vector2(lg, 0), pm + Vector2(0, 3), pm + Vector2(-lg, 0)]), Color("#e8b93a"))
			draw_colored_polygon(PackedVector2Array([pm + Vector2(0, -3), pm + Vector2(lg, 0), pm + Vector2(0, 0)]), Color("#fff0a8"))
			continue
		var c := Color("#ff4060") if k.kind == "hp" else Color("#4a8bff")
		var p := Vector2(k.x + 4, k.y + 4 + b)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -5), p + Vector2(4, 0), p + Vector2(0, 5), p + Vector2(-4, 0)]), c)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -5), p + Vector2(4, 0), p + Vector2(0, 0)]), c.lightened(0.5))
	for q in game.parts:
		if q.has("po"):
			var kp: float = 1.0 - q.life / q.vida          # 0 nasce, 1 some
			var cp := Gfx.col(q.c, 0.5 * (1.0 - kp) * (1.0 - kp))
			draw_circle(Vector2(q.x, q.y), q.s * (0.7 + kp * 1.6), cp)
		elif q.has("tipo"):
			var tp: String = q.tipo
			var kq: float = 1.0 - q.life / q.vida
			if tp == "fumaca":
				Efeitos.brilho(self, Vector2(q.x, q.y), q.s * (1.2 + kq * 2.4), q.c, 0.75 * minf(1.0, kq * 5.0) * (1.0 - kq))
			elif tp == "lasca":
				var pl := Vector2(q.x, minf(q.y, GameData.GROUND - 1.0))
				var rl: float = q.f + (q.life * 0.4 if q.y < GameData.GROUND - 1.0 else 0.0)
				var tl: float = q.s
				draw_colored_polygon(PackedVector2Array([pl + Vector2(tl, 0).rotated(rl), pl + Vector2(tl, 0).rotated(rl + 2.2), pl + Vector2(tl, 0).rotated(rl + 4.3)]), Gfx.col(q.c, minf(1.0, q.life / 8.0)))
	for o in game.projs:
		_proj(o)
	for f in game.fx:
		if f.get("normal", false):
			f.draw.call(self, f.t / float(f.life))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	for n in game.nums:
		# número de dano: nasce grande e encolhe, sobe rápido e desacelera
		var u: float = n.t / 45.0
		var pulo := maxf(0.0, 1.0 - n.t / 6.0)
		var sz: int = int(roundf((13 if n.big else 9) * (1.0 + 0.55 * pulo)))
		Ui.txt(self, n.v, n.x, n.y - (1.0 - (1.0 - u) * (1.0 - u)) * 20.0, n.c, sz, 1, minf(1.0, (45 - n.t) / 12.0), Ui.neg())

func _draw_luz() -> void:
	for k in game.pickups:
		var b := sin(k.t * 0.15) * 1.5
		var c := Color("#ff4060") if k.kind == "hp" else (Color("#4a8bff") if k.kind == "mp" else Color("#e8b93a"))
		luz.draw_circle(Vector2(k.x + 4, k.y + 4 + b), 8 if k.kind != "ouro" else 4, Color(c.r, c.g, c.b, 0.25 + 0.1 * sin(k.t * 0.2)))
	for q in game.parts:
		if q.has("po"): continue
		if q.has("tipo"):
			_part_luz(q)
			continue
		var a: float = q.get("a", minf(1.0, q.life / 10.0))
		var c := Gfx.col(q.c, a)
		var p := Vector2(q.x, q.y)
		var v := Vector2(q.vx, q.vy)
		luz.draw_circle(p, q.s * 1.4, Color(c.r, c.g, c.b, a * 0.16))
		if v.length_squared() > 0.5:
			# faísca em agulha: comprida na direção em que voa, com o miolo claro
			var d := v.normalized()
			var comp: float = minf(v.length() * 2.6, 12.0) + q.s
			var lat: Vector2 = Vector2(-d.y, d.x) * q.s * 0.5
			luz.draw_colored_polygon(PackedVector2Array([p + d * q.s, p + lat, p - d * comp, p - lat]), c)
			luz.draw_line(p, p - d * comp * 0.5, Color(1, 1, 1, a * 0.7), 0.6)
		else:
			luz.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -q.s), p + Vector2(q.s * 0.7, 0), p + Vector2(0, q.s), p + Vector2(-q.s * 0.7, 0)]), c)
	for r in game.rastros:
		Gfx.rastro(luz, r)
	for o in game.projs:
		_proj_luz(o)
	for f in game.fx:
		if not f.get("normal", false) and f.get("camada", "luz") == "luz":
			f.draw.call(luz, f.t / float(f.life))
	luz.draw_set_transform_matrix(Transform2D.IDENTITY)
	_auras_luz()

func _draw_energia() -> void:
	_auras_energia()
	for o in game.projs:
		_proj_energia(o)
	for f in game.fx:
		if f.get("camada", "") == "energia":
			f.draw.call(energia, f.t / float(f.life))
	energia.draw_set_transform_matrix(Transform2D.IDENTITY)

func _proj(o: Dictionary) -> void:
	var x: float = o.x
	var y: float = o.y
	match o.kind:
		"arrow":
			var c := Color(o.get("color", "#e8dcc0"))
			var meio := Vector2(x + o.w / 2, y + o.h / 2)
			var dv := Vector2(o.vx, o.vy).normalized()
			var nv := Vector2(-dv.y, dv.x)
			var comp: float = o.w / 2
			draw_line(meio - dv * comp, meio + dv * comp, c.darkened(0.3), 1.0 if o.h < 4 else 1.8)
			var ponta := meio + dv * comp
			draw_colored_polygon(PackedVector2Array([ponta + dv * 3, ponta + nv * 1.8, ponta - nv * 1.8]), Color("#e8eef8"))
		"rain":
			draw_line(Vector2(x + 1.5, y), Vector2(x + 1.5, y + o.h), Color("#e8dcc0"), 1.0)
		"rock":
			draw_colored_polygon(PackedVector2Array([Vector2(x, y + 3), Vector2(x + 3, y), Vector2(x + o.w, y + 2), Vector2(x + o.w - 1, y + o.h), Vector2(x + 2, y + o.h)]), Color("#3a3550"))
			draw_line(Vector2(x + 3, y + 1), Vector2(x + o.w - 1, y + 2), Color("#8a84b8"), 1.0)

## Flecha "forte": perfurante, pesada ou de habilidade (ganha cone de energia e anéis de vento).
func _flecha_forte(o: Dictionary) -> bool:
	return o.get("pierce", false) or o.get("heavy", false)

func _proj_luz(o: Dictionary) -> void:
	var c := Vector2(o.x + o.w / 2, o.y + o.h / 2)
	var v := Vector2(o.vx, o.vy)
	var d := v.normalized()
	var hist: Array = o.get("hist", [])
	match o.kind:
		"arrow":
			var cor := Color(o.get("color", "#cfeaff"))
			var forte := _flecha_forte(o)
			var ponta: Vector2 = c + d * (o.w / 2 + 2.0)
			Efeitos.fita(luz, [ponta] + hist, 5.5 if forte else 2.8, cor, 0.9)
			Efeitos.brilho(luz, ponta, 10.0 if forte else 5.5, cor, 0.8)
			if forte or o.get("skill", false): Efeitos.estrela(luz, ponta, 12.0 if forte else 8.0, cor, 0.9, o.t * 0.35)
		"rain":
			var cr := Color(Efeitos.VENTO)
			var pr: Vector2 = c + d * 6.0
			Efeitos.fita(luz, [pr, c - d * 8.0, c - d * 22.0, c - d * 38.0], 3.2, cr, 0.85)
			luz.draw_line(pr, c - d * 7.0, Color(1, 1, 1, 0.9), 0.9)
			Efeitos.brilho(luz, pr, 7.0, cr, 0.75)
		"bolt":
			Efeitos.fita(luz, [c] + hist, 6.5, "#59d0ff", 0.85)
			Efeitos.brilho(luz, c, 13.0, "#59d0ff", 0.65)
			Efeitos.brilho(luz, c, 5.5, Color.WHITE, 1.0)
			var ang: float = o.t * 0.55
			luz.draw_arc(c, 6.5, ang, ang + 1.7, 8, Color(0.75, 0.95, 1.0, 0.9), 1.0)
			luz.draw_arc(c, 6.5, ang + PI, ang + PI + 1.7, 8, Color(0.75, 0.95, 1.0, 0.9), 1.0)
		"fire":
			Efeitos.brilho(luz, c, 20.0, "#ff7a2a", 0.5)
			Efeitos.brilho(luz, c, 6.5, "#fff3c4", 0.95)
		"meteor":
			Efeitos.brilho(luz, c, 44.0, "#ff4d2e", 0.5)
			Efeitos.brilho(luz, c, 13.0, "#fff3c4", 1.0)
			Efeitos.estrela(luz, c, 30.0, "#ffb347", 0.6, o.t * 0.2)
		"ebolt":
			Efeitos.fita(luz, [c] + hist, 5.5, "#b06bff", 0.8)
			Efeitos.brilho(luz, c, 11.0, "#b06bff", 0.7)
			Efeitos.brilho(luz, c, 4.0, Color.WHITE, 1.0)
			luz.draw_arc(c, 5.5, -o.t * 0.5, -o.t * 0.5 + 2.2, 8, Color(0.9, 0.7, 1.0, 0.9), 1.0)
		"wave":
			Efeitos.brilho(luz, Vector2(c.x, o.y + o.h), o.w * 0.9, "#ff7a3a", 0.6, Vector2(1.0, 0.3))

func _proj_energia(o: Dictionary) -> void:
	var c := Vector2(o.x + o.w / 2, o.y + o.h / 2)
	var d := Vector2(o.vx, o.vy).normalized()
	match o.kind:
		"arrow":
			if _flecha_forte(o):
				var ponta: Vector2 = c + d * (o.w / 2 + 3.0)
				Efeitos.feixe(energia, ponta, ponta - d * (26.0 + o.w), 11.0, 1.0, o.get("color", "#cfeaff"), 0.95, 1.0)
		"rain":
			Efeitos.feixe(energia, c + d * 6.0, c - d * 30.0, 6.0, 0.6, Efeitos.VENTO, 0.9, 1.0)
		"bolt":
			Efeitos.bola(energia, c, 6.0, "#59d0ff", 0.9)
		"fire":
			Efeitos.feixe(energia, c + d * 2.0, c - d * 24.0, 13.0, 2.0, "#ff6a2a", 0.75, 1.0)
			Efeitos.bola(energia, c, 8.5, "#ff8a3d", 0.95)
		"meteor":
			Efeitos.feixe(energia, c + d * 4.0, c - d * 78.0, 28.0, 3.0, "#ff5a26", 0.8, 1.0)
			Efeitos.bola(energia, c, 15.0, "#ff4d2e", 1.0)
		"ebolt":
			Efeitos.bola(energia, c, 5.0, "#b06bff", 0.9)
		"wave":
			for i in 3:
				var bx: float = o.x + (i + 0.5) * o.w / 3.0
				var alt: float = o.h * (0.9 + 0.5 * sin(o.t * 0.5 + i * 2.0))
				Efeitos.feixe(energia, Vector2(bx, o.y + o.h), Vector2(bx + signf(o.vx) * 5.0, o.y + o.h - alt - 6.0), o.w / 2.0, 1.0, "#ff7a3a", 0.9, 1.0)

func _part_luz(q: Dictionary) -> void:
	var tp: String = q.tipo
	var k: float = 1.0 - q.life / q.vida
	var p := Vector2(q.x, q.y)
	match tp:
		"brasa":
			var a: float = minf(1.0, q.life / 10.0) * (0.55 + 0.45 * sin(q.f + q.life * 0.9))
			Efeitos.brilho(luz, p, q.s * 3.4, q.c, a * 0.55)
			luz.draw_rect(Rect2(p.x - q.s * 0.4, p.y - q.s * 0.4, q.s * 0.8, q.s * 0.8), Color(1.0, 0.96, 0.82, a))
		"chama":
			var cor: Color
			if k < 0.2: cor = Color(1.0, 1.0, 0.85).lerp(Color("#ffd23f"), k / 0.2)
			elif k < 0.5: cor = Color("#ffd23f").lerp(Color("#ff7a2a"), (k - 0.2) / 0.3)
			else: cor = Color("#ff7a2a").lerp(Color("#8a1c12"), (k - 0.5) / 0.5)
			var r: float = q.s * (0.7 + 0.9 * k) * (1.0 - k * k * 0.6)
			Efeitos.brilho(luz, p, r * 1.7, cor, 0.85 * (1.0 - k))
		"centelha":
			var a2: float = minf(1.0, q.life / 8.0) * (0.35 + 0.65 * absf(sin(q.f + q.life * 0.5)))
			Efeitos.estrela(luz, p, q.s * 2.6, q.c, a2)

# ---------------- Auras dos heróis (carga de mana e despertar) ----------------
func _auras_energia() -> void:
	var t := Engine.get_physics_frames()
	for p in game.players:
		if p.dead: continue
		var pe: Vector2 = p.position
		if p.desperto > 0:
			# chamas de energia subindo em volta do herói desperto
			var cf := Color(GameData.FURIA[p.d.id].c)
			var fim := minf(1.0, p.desperto / 60.0)
			# línguas de fogo pelos lados (o corpo fica à vista) e uma chama baixa nos pés
			for i in 4:
				var lado: float = -1.0 if i < 2 else 1.0
				var dx: float = lado * (8.5 + (i % 2) * 3.5) + sin(t * 0.21 + i * 1.7) * 1.2
				var alt: float = 17.0 + 13.0 * absf(sin(t * 0.13 + i * 2.1))
				Efeitos.feixe(energia, pe + Vector2(dx, 1), pe + Vector2(dx * 1.25, -alt - 6.0), 5.0, 0.6, cf, 0.45 * fim, 0.8 * fim)
			Efeitos.feixe(energia, pe + Vector2(-10, 0), pe + Vector2(10, 0), 7.0, 7.0, cf, 0.55 * fim, 0.55 * fim)
		if p.state == "charge":
			var c := Color(p.d.skills[clampi(p.charge_lv, 0, 2)].c)
			var carga: float = p.charge
			Efeitos.anel(energia, pe + Vector2(0, -1), 12.0 + carga * 5.0, 5.0 + carga * 1.5, c, 0.8, Vector2(1.0, 0.3))
			Efeitos.feixe(energia, pe, pe + Vector2(0, -34.0 - carga * 9.0), 9.0 + carga * 2.5, 2.0, c, 0.2 + 0.06 * carga, 0.5)

func _auras_luz() -> void:
	var t := Engine.get_physics_frames()
	for p in game.players:
		if p.dead: continue
		var pe: Vector2 = p.position
		if p.desperto > 0:
			var fim := minf(1.0, p.desperto / 60.0)
			Efeitos.brilho(luz, pe + Vector2(0, -15), 24.0, GameData.FURIA[p.d.id].c, 0.2 * fim)
		if p.state == "charge":
			var c := Color(p.d.skills[clampi(p.charge_lv, 0, 2)].c)
			Efeitos.brilho(luz, pe + Vector2(0, -13), 17.0 + p.charge * 4.0, c, 0.24 + 0.08 * sin(t * 0.35))

## A cada passo do jogo: guarda o caminho dos projéteis (para as fitas de luz) e solta as partículas que eles deixam.
func _physics_process(_d: float) -> void:
	if game == null or game.paused or game.hitstop > 0:
		return
	for o in game.projs:
		var c := Vector2(o.x + o.w / 2, o.y + o.h / 2)
		if not o.has("hist"): o.hist = []
		var hist: Array = o.hist
		hist.push_front(c)
		if hist.size() > 8: hist.pop_back()
		var t: int = o.t
		match o.kind:
			"fire":
				Efeitos.chamas(game, c, 1, 5.0, 0.7, 2.0)
				if t % 4 == 0: Efeitos.fumaca(game, c, 1, 3.0, 2.0)
			"meteor":
				Efeitos.chamas(game, c, 2, 9.0, 1.0, 6.0)
				if t % 2 == 0: Efeitos.brasas(game, c, 1, "#ffb347", 1.5, 6.0)
				if t % 3 == 0: Efeitos.fumaca(game, c - Vector2(o.vx, o.vy) * 3.0, 1, 6.0, 4.0)
			"bolt":
				if t % 3 == 0: Efeitos.centelhas(game, c, 1, "#9ff0ff", 2.0, 0.3)
			"ebolt":
				if t % 4 == 0: Efeitos.centelhas(game, c, 1, "#d08bff", 2.0, 0.3)
			"arrow":
				if _flecha_forte(o) and t % 3 == 1:
					# anéis de vento que a flecha deixa para trás
					var ang := Vector2(o.vx, o.vy).angle()
					var cor: String = o.get("color", "#cfeaff")
					var raio: float = 5.0 + o.w * 0.18
					Efeitos.fx(game, 10, func(cv: CanvasItem, k: float):
						cv.draw_set_transform(c, ang, Vector2(0.32, 1.0))
						cv.draw_arc(Vector2.ZERO, raio * (0.5 + 1.3 * Efeitos.sai(k)), 0, TAU, 20, Gfx.col(cor, 0.85 * (1.0 - k)), 1.5 * (1.0 - k) + 0.3)
						cv.draw_set_transform_matrix(Transform2D.IDENTITY))
					Efeitos.centelhas(game, c, 1, cor, 3.0, 0.4)
	for p in game.players:
		if p.dead: continue
		var id: int = p.get_instance_id()
		var pe: Vector2 = p.position
		if p.desperto > 0 and Engine.get_physics_frames() % 5 == 0:
			Efeitos.brasas(game, pe + Vector2(randf_range(-9, 9), -randf_range(2, 30)), 1, GameData.FURIA[p.d.id].c, 0.5, 1.0)
		var lv: int = p.charge_lv if p.state == "charge" else 0
		if lv > int(_carga_ant.get(id, 0)):
			var cor2: String = p.d.skills[lv - 1].c
			Efeitos.coluna(game, pe.x, pe.y, 44.0 + lv * 14.0, 9.0 + lv * 3.0, cor2, 14)
			Efeitos.centelhas(game, pe + Vector2(0, -14), 4 + lv * 2, cor2, 12.0, 1.4)
			Efeitos.reflexo(game, pe + Vector2(0, -16), 16.0 + lv * 5.0, cor2, 10)
		_carga_ant[id] = lv
