extends Node2D
## Chão, plataformas, cenário, barreiras e portal (coordenadas do mundo).

var game

func _draw() -> void:
	var cx: float = game.cam_x
	var W := GameData.W
	var G := GameData.GROUND
	for c in [1180, 1330, 1560, 1760, 1990, 2240]:
		if c < cx - 40 or c > cx + W + 40: continue
		Gfx.rect(self, c, 150, 14, 80, "#4a4560"); Gfx.rect(self, c - 3, 146, 20, 6, "#5c5675"); Gfx.rect(self, c + 2, 152, 3, 70, "#3b374f")
		if c % 3 == 0: Gfx.rect(self, c, 120, 14, 26, "#4a4560")
	for c in [2320, 2470, 2600, 2740]:
		Gfx.rect(self, c, 110, 16, 120, "#3a2e3f"); Gfx.rect(self, c - 4, 104, 24, 8, "#4a3b4f")
		Gfx.rect(self, c + 4, 130, 8, 18, "#7a1f2b"); Gfx.rect(self, c + 5, 148, 6, 4, "#7a1f2b")
	# acampamento (início)
	Gfx.rect(self, 30, 196, 3, 34, "#6b4a2b"); Gfx.rect(self, 18, 198, 28, 12, "#8b6a3b")
	Gfx.text(self, "INÍCIO", 32, 204, "#fff3c4", 6, 1)
	Gfx.tri(self, Vector2(80, 230), Vector2(102, 200), Vector2(124, 230), "#7a3b2b"); Gfx.rect(self, 100, 214, 5, 16, "#2a1a14")
	var fl := sin(game.t * 0.3)
	Gfx.rect(self, 140, 226, 12, 4, "#4a2f1d")
	Gfx.tri(self, Vector2(141, 226), Vector2(146, 214 + fl * 2), Vector2(151, 226), "#ffb347"); Gfx.rect(self, 144, 220, 4, 6, "#ffe08a")
	# chão
	Gfx.rect(self, cx - 10, G, W + 20, GameData.H - G, "#4a3324")
	Gfx.rect(self, cx - 10, G, W + 20, 4, "#4f9a43"); Gfx.rect(self, cx - 10, G + 4, W + 20, 2, "#3a7a35")
	var x := floorf(cx / 16) * 16
	while x < cx + W + 16:
		var hh := int(x * 7919) % 13
		Gfx.rect(self, x + hh % 9, G + 10 + hh, 4, 2, "#5c4130")
		if hh % 4 == 0: Gfx.rect(self, x + 3, G - 2, 1, 2, "#6fbf5a")
		x += 16
	for p in GameData.PLATS:
		if p.x > cx + W or p.x + p.w < cx: continue
		Gfx.rect(self, p.x, p.y, p.w, 8, "#6d6884"); Gfx.rect(self, p.x, p.y, p.w, 2, "#8a85a3")
		Gfx.rect(self, p.x, p.y + 8, p.w, 2, "#4a4560"); Gfx.rect(self, p.x, p.y - 1, p.w, 2, "#4f9a43")
		var i := 8
		while i < p.w:
			Gfx.rect(self, p.x + i, p.y + 2, 1, 6, "#57526c"); i += 16
	# barreiras rúnicas
	for b in game.barriers():
		if b < cx - 10 or b > cx + W + 10: continue
		var yy := 40
		while yy < G:
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
		Gfx.text(self, "FIM", px, 160, "#e6fdff", 8, 1)
	Gfx.rect(self, GameData.PORTAL_X - 15, 226, 30, 4, "#5c5675")
