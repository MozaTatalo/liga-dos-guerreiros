extends Node2D
## Projéteis, itens, partículas, efeitos e números de dano.

var game

func _draw() -> void:
	for k in game.pickups:
		var b := sin(k.t * 0.15) * 1.5
		Gfx.rect(self, k.x, k.y + b, 8, 8, "#e0413a" if k.kind == "hp" else "#3a7bff")
		Gfx.rect(self, k.x + 2, k.y + 2 + b, 3, 3, "#ffffff")
	for o in game.projs:
		_proj(o)
	for q in game.parts:
		var a: float = q.get("a", minf(1.0, q.life / 10.0))
		Gfx.rect(self, roundf(q.x - q.s / 2), roundf(q.y - q.s / 2), q.s, q.s, q.c, a)
	for f in game.fx:
		f.draw.call(self, f.t / float(f.life))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	for n in game.nums:
		Gfx.text(self, n.v, n.x, n.y - n.t * 0.5, n.c, 11 if n.big else 8, 1, minf(1.0, (45 - n.t) / 15.0))

func _proj(o: Dictionary) -> void:
	var x := roundf(o.x)
	var y := roundf(o.y)
	match o.kind:
		"arrow":
			var f := signf(o.vx)
			Gfx.rect(self, x, y + 1, o.w, 1, o.get("color", "#e8dcc0"))
			Gfx.rect(self, x + o.w - 2 if f > 0 else x, y, 2, 3, "#cfd6e0")
			Gfx.rect(self, x if f > 0 else x + o.w - 3, y, 3, 3, "#cc3333")
		"rain":
			Gfx.rect(self, x + 1, y, 1, o.h, "#e8dcc0"); Gfx.rect(self, x, y + o.h - 2, 3, 2, "#cfd6e0")
		"bolt":
			draw_circle(Vector2(x + 5, y + 4), 5, Gfx.col("#59d0ff")); Gfx.rect(self, x + 3, y + 2, 4, 4, "#e6fdff")
		"fire":
			draw_circle(Vector2(x + 6, y + 6), 6, Gfx.col("#ff8a3d")); Gfx.rect(self, x + 3, y + 3, 6, 6, "#ffd23f"); Gfx.rect(self, x + 5, y + 5, 2, 2, "#ffffff")
		"meteor":
			draw_circle(Vector2(x + 9, y + 9), 9, Gfx.col("#ff4d2e")); Gfx.rect(self, x + 4, y + 4, 10, 10, "#ffb347"); Gfx.rect(self, x + 7, y + 7, 4, 4, "#fff3c4")
		"ebolt":
			Gfx.rect(self, x, y, o.w, o.h, "#ffcf4a"); Gfx.rect(self, x, y + 1, o.w, 1, "#ffffff")
		"wave":
			Gfx.rect(self, x, y + 4, o.w, o.h - 4, "#d9a066", 0.8); Gfx.rect(self, x + 2, y, o.w - 4, 6, "#ffcf8a", 0.8)
		"rock":
			Gfx.rect(self, x, y, o.w, o.h, "#7d6e5e"); Gfx.rect(self, x + 2, y + 2, 4, 3, "#a39280")
