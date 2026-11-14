extends Node2D
## Projéteis, itens, partículas, efeitos e números de dano.
## Tudo que brilha é desenhado num nó com mistura aditiva (luz somando, no estilo dos jogos de ação anime).

var game
var luz: Node2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	luz = Node2D.new()
	var m := CanvasItemMaterial.new(); m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	luz.material = m
	luz.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	luz.draw.connect(_draw_luz)
	add_child(luz)

func _process(_d: float) -> void:
	luz.queue_redraw()

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
	for o in game.projs:
		_proj(o)
	for f in game.fx:
		if f.get("normal", false):
			f.draw.call(self, f.t / float(f.life))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	for n in game.nums:
		var sz: int = (13 if n.big else 9) + (3 if n.t < 4 else 0)
		Ui.txt(self, n.v, n.x, n.y - n.t * 0.5, n.c, sz, 1, minf(1.0, (45 - n.t) / 15.0), Ui.neg())

func _draw_luz() -> void:
	for k in game.pickups:
		var b := sin(k.t * 0.15) * 1.5
		var c := Color("#ff4060") if k.kind == "hp" else (Color("#4a8bff") if k.kind == "mp" else Color("#e8b93a"))
		luz.draw_circle(Vector2(k.x + 4, k.y + 4 + b), 8 if k.kind != "ouro" else 4, Color(c.r, c.g, c.b, 0.25 + 0.1 * sin(k.t * 0.2)))
	for q in game.parts:
		var a: float = q.get("a", minf(1.0, q.life / 10.0))
		var c := Gfx.col(q.c, a)
		var p := Vector2(q.x, q.y)
		luz.draw_circle(p, q.s * 1.3, Color(c.r, c.g, c.b, a * 0.18))
		luz.draw_circle(p, q.s * 0.75, c)
		if absf(q.vx) + absf(q.vy) > 1.2:
			luz.draw_line(p, p - Vector2(q.vx, q.vy) * 2.2, Color(c.r, c.g, c.b, a * 0.6), q.s * 0.6)
	for o in game.projs:
		_proj_luz(o)
	for f in game.fx:
		if not f.get("normal", false):
			f.draw.call(luz, f.t / float(f.life))
	luz.draw_set_transform_matrix(Transform2D.IDENTITY)

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

func _proj_luz(o: Dictionary) -> void:
	var x: float = o.x
	var y: float = o.y
	var c := Vector2(x + o.w / 2, y + o.h / 2)
	match o.kind:
		"arrow":
			var cor := Color(o.get("color", "#9fd3ff"))
			luz.draw_line(c, c - Vector2(o.vx, o.vy) * 3.0, Color(cor.r, cor.g, cor.b, 0.45), 2.0)
		"bolt":
			luz.draw_circle(c, 9, Color(0.35, 0.8, 1.0, 0.25)); luz.draw_circle(c, 5, Color("#59d0ff")); luz.draw_circle(c, 2.5, Color.WHITE)
			luz.draw_line(c, c - Vector2(o.vx, o.vy) * 3.0, Color(0.35, 0.8, 1.0, 0.5), 4.0)
		"fire":
			luz.draw_circle(c, 12, Color(1.0, 0.45, 0.1, 0.25)); luz.draw_circle(c, 7, Color("#ff8a3d")); luz.draw_circle(c, 3.5, Color("#fff3c4"))
		"meteor":
			luz.draw_line(c, c - Vector2(o.vx, o.vy) * 6.0, Color(1.0, 0.4, 0.15, 0.55), 12.0)
			luz.draw_circle(c, 18, Color(1.0, 0.35, 0.1, 0.25)); luz.draw_circle(c, 10, Color("#ff4d2e")); luz.draw_circle(c, 5, Color("#fff3c4"))
		"ebolt":
			luz.draw_circle(c, 8, Color(0.75, 0.4, 1.0, 0.3)); luz.draw_circle(c, 4, Color("#d08bff")); luz.draw_circle(c, 2, Color.WHITE)
			luz.draw_line(c, c - Vector2(o.vx, o.vy) * 3.0, Color(0.75, 0.4, 1.0, 0.45), 3.0)
		"wave":
			for i in 3:
				var hh: float = o.h * (0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.02 + i * 2.0 + x * 0.3))
				luz.draw_colored_polygon(PackedVector2Array([Vector2(x + i * o.w / 3.0, y + o.h), Vector2(x + (i + 0.5) * o.w / 3.0, y + o.h - hh - 4), Vector2(x + (i + 1) * o.w / 3.0, y + o.h)]), Color(1.0, 0.55, 0.25, 0.75))
		"rain":
			luz.draw_line(Vector2(x + 1.5, y), Vector2(x + 1.5, y - 8), Color(0.6, 1.0, 0.6, 0.3), 2.0)
