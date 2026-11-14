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
