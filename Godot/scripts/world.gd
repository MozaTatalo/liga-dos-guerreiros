extends Node2D
## Chão, plataformas, cenário, barreiras e portal (coordenadas do mundo).

var game

func _draw() -> void:
	var cx: float = game.cam_x
	var W := GameData.W
	# o chão, as plataformas e as ruínas agora são 3D (Cenario3D); aqui fica só o que é do jogo
	# tela escurecida durante a habilidade suprema (fica atrás dos personagens)
	if game.dim_t > 0:
		Gfx.rect(self, cx - 20, -40, W + 40, GameData.H + 80, "#05030c", 0.62 * minf(1.0, game.dim_t / 14.0))
	# avisos de golpe no chão
	for av in game.avisos:
		var k: float = clampf(float(av.t) / av.dur, 0.0, 1.0)
		var a: float = 1.0 if av.t < av.dur else maxf(0.0, 1.0 - (av.t - av.dur) / 6.0)
		var pisca: float = 0.75 + 0.25 * sin(av.t * 0.5)
		if av.faixa:
			var r := Rect2(av.x - av.w / 2, GameData.GROUND - 5, av.w, 7)
			draw_rect(r, Color(1.0, 0.16, 0.12, 0.2 * a * pisca))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 1.2)), Color(1.0, 0.4, 0.3, 0.8 * a * pisca))
			draw_rect(Rect2(r.position + Vector2(0, 5.8), Vector2(r.size.x, 1.2)), Color(1.0, 0.4, 0.3, 0.8 * a * pisca))
		else:
			draw_set_transform(Vector2(av.x, GameData.GROUND - 1), 0.0, Vector2(1, 0.22))
			draw_circle(Vector2.ZERO, av.w / 2, Color(1.0, 0.16, 0.12, 0.26 * a))
			draw_circle(Vector2.ZERO, av.w / 2 * k, Color(1.0, 0.25, 0.15, 0.4 * a * pisca))
			draw_arc(Vector2.ZERO, av.w / 2, 0, TAU, 36, Color(1.0, 0.45, 0.35, 0.95 * a), 1.4)
			draw_set_transform_matrix(Transform2D.IDENTITY)
	# placa de início
	Gfx.rect(self, 30, 196, 3, 34, "#3a2a20"); Gfx.rect(self, 18, 198, 28, 12, "#4a3528")
	Gfx.text(self, "INÍCIO", 32, 204, "#e8d9b0", 5, 1)
	# barreiras rúnicas
	for b in game.barriers():
		if b < cx - 10 or b > cx + W + 10: continue
		var yy := 40
		while yy < GameData.GROUND:
			var o := sin(game.t * 0.15 + yy * 0.2) * 2
			Gfx.rect(self, b - 2 + o, yy, 4, 4, "#8f6bff", 0.55); Gfx.rect(self, b + o, yy + 1, 1, 2, "#d7c9ff")
			yy += 6
	# portal (fim)
	if game.boss_dead:
		var px := GameData.PORTAL_X
		var cols := ["#3a6bff", "#59d0ff", "#e6fdff"]
		for i2 in 3:
			draw_set_transform(Vector2(px, 200), 0.0, Vector2(1, 2))
			draw_circle(Vector2.ZERO, 14 - i2 * 4, Gfx.col(cols[i2], 0.35 + i2 * 0.2))
		draw_set_transform_matrix(Transform2D.IDENTITY)
		if game.t % 3 == 0:
			game.parts.append({"x": px + randf_range(-12, 12), "y": 200 + randf_range(-20, 20), "vx": 0.0, "vy": -0.6, "life": 30.0, "c": "#9ff0ff", "s": 2.0, "g": 0.0})
		Ui.titulo(self, "PORTAL", px, 160, "#e6fdff", 8)
	Gfx.rect(self, GameData.PORTAL_X - 15, 226, 30, 4, "#33364a")
