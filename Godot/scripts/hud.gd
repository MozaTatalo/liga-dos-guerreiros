extends Node2D
## Interface na tela: vida, mana, habilidades, combo, chefe e telas de fim.

var game

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _draw() -> void:
	var W := GameData.W
	var H := GameData.H
	for i in game.players.size():
		_player_panel(game.players[i], 6 + i * 160)
	_skills(game.players[0])
	Gfx.text(self, "%ds" % int(game.t / 60), W - 8, 12, "#ffffff", 8, 2)
	if game.combo > 1:
		var sz := 10 + mini(6, game.combo / 5) + (3 if game.combo_t > 110 else 0)
		Gfx.text(self, "%d COMBO" % game.combo, W - 8, 30, "#ffd23f", sz, 2)
	var lead: float = 0.0
	for p in game.players: lead = maxf(lead, p.x)
	var pr := clampf(lead / 3000.0, 0, 1)
	Gfx.rect(self, W / 2 - 60, 8, 120, 3, "#222222"); Gfx.rect(self, W / 2 - 60, 8, 120 * pr, 3, "#8f6bff"); Gfx.rect(self, W / 2 - 61 + 120 * pr, 6, 3, 7, "#ffffff")
	for e in game.enemies:
		if e.boss:
			var bx := 150.0
			var bw := 310.0
			var by := H - 18
			Gfx.rect(self, bx - 1, by - 1, bw + 2, 10, "#000000"); Gfx.rect(self, bx, by, bw, 8, "#220000")
			Gfx.rect(self, bx, by, bw * e.hp / e.maxhp, 8, "#c0392b"); Gfx.rect(self, bx, by, bw * e.hp / e.maxhp, 2, "#ff7b6b")
			Gfx.text(self, "ESPECTRO ANCIÃO", bx, by - 7, "#ffcf8a", 7)
	if game.msg_t > 0 and game.result == null:
		Gfx.text(self, game.msg, W / 2, 70, "#fff3c4", 12, 1, minf(1.0, game.msg_t / 20.0))
	if game.paused:
		Gfx.rect(self, 0, 0, W, H, "#000000", 0.5)
		Gfx.text(self, "PAUSADO", W / 2, H / 2, "#ffffff", 16, 1); Gfx.text(self, "P para continuar", W / 2, H / 2 + 18, "#cccccc", 8, 1)
	if game.alive_players().is_empty() and game.all_dead_t > 40:
		Gfx.rect(self, 0, 0, W, H, "#280000", 0.5)
		Gfx.text(self, "VOCÊ CAIU...", W / 2, H / 2 - 10, "#ff8080", 20, 1)
		Gfx.text(self, "R: tentar de novo   ·   Enter: escolher personagem", W / 2, H / 2 + 16, "#ffffff", 8, 1)
	if game.result != null:
		var r: Dictionary = game.result
		Gfx.rect(self, W / 2 - 120, 50, 240, 170, "#0a0a1e", 0.88); Gfx.rect(self, W / 2 - 120, 50, 240, 2, "#ffd23f")
		Gfx.text(self, "FASE CONCLUÍDA!", W / 2, 70, "#ffd23f", 16, 1)
		Gfx.text(self, "Tempo: %.1fs" % r.time, W / 2 - 90, 100, "#ffffff", 9)
		Gfx.text(self, "Combo máximo: %d" % game.max_combo, W / 2 - 90, 116, "#ffffff", 9)
		Gfx.text(self, "Dano recebido: %d" % r.dt, W / 2 - 90, 132, "#ffffff", 9)
		Gfx.text(self, "Inimigos: %d" % game.kills, W / 2 - 90, 148, "#ffffff", 9)
		Gfx.text(self, "RANK", W / 2 + 70, 100, "#cccccc", 9, 1)
		var rc: String = {"S": "#ffd23f", "A": "#7dff8a", "B": "#7db8ff", "C": "#cccccc"}[r.rank]
		Gfx.text(self, r.rank, W / 2 + 70, 130, rc, 36, 1)
		Gfx.text(self, "Enter: menu   ·   R: jogar de novo", W / 2, 200, "#cccccc", 8, 1)

func _player_panel(p: Hero, px: float) -> void:
	var d := p.d
	Gfx.rect(self, px, 6, 150, 34, "#0a0a19", 0.75); Gfx.rect(self, px, 6, 150, 1, d.trim)
	Gfx.rect(self, px + 3, 9, 26, 28, "#24233f")
	# retrato: recorte da cabeça do próprio boneco 3D (ao vivo, até pisca)
	if p.view and p.view.vp:
		draw_texture_rect_region(p.view.vp.get_texture(), Rect2(px + 3, 9, 26, 28), Rect2(113, 72, 84, 90))
	Gfx.text(self, "%s · %s" % [d.name, d.cls], px + 34, 13, "#ffffff", 7)
	Gfx.rect(self, px + 34, 19, 110, 7, "#330000"); Gfx.rect(self, px + 34, 19, 110 * p.hp / d.hp, 7, "#e0413a"); Gfx.rect(self, px + 34, 19, 110 * p.hp / d.hp, 2, "#ff8a80")
	Gfx.text(self, "%d/%d" % [ceili(p.hp), d.hp], px + 89, 23, "#ffffff", 6, 1)
	Gfx.rect(self, px + 34, 29, 110, 5, "#0a1640"); Gfx.rect(self, px + 34, 29, 110 * p.mp / d.mp, 5, "#3a7bff")
	Gfx.text(self, "%d" % int(p.mp), px + 89, 32, "#e6eeff", 5, 1)

func _skills(p: Hero) -> void:
	var H := GameData.H
	var keys := ["A", "S", "D"]
	for i in 4:
		var x := 8 + i * 28
		var y := H - 34
		Gfx.rect(self, x, y, 24, 24, "#0a0a19", 0.8)
		if i < 3:
			var sk: Dictionary = p.d.skills[i]
			Gfx.rect(self, x + 3, y + 3, 18, 18, sk.c if p.mp >= sk.mp else "#555566")
			Gfx.rect(self, x + 3, y + 3, 18, 9, "#ffffff", 0.35)
			if p.cds[i] > 0:
				Gfx.rect(self, x, y, 24, 24.0 * p.cds[i] / sk.cd, "#000000", 0.7)
				Gfx.text(self, str(ceili(p.cds[i] / 60.0)), x + 12, y + 12, "#ffffff", 8, 1)
			Gfx.text(self, keys[i], x + 3, y + 3, "#ffffff", 6)
			Gfx.text(self, str(sk.mp), x + 21, y + 20, "#9fc0ff", 5, 2)
		else:
			Gfx.rect(self, x + 3, y + 3, 18, 18, "#555566" if p.dash_cd > 0 else "#cfd3e6")
			Gfx.text(self, "C", x + 3, y + 3, "#ffffff", 6)
			Gfx.text(self, "esq", x + 12, y + 13, "#222233", 5, 1)
	if p.deny_t > 0:
		Gfx.text(self, "Sem mana / recarregando", 8, H - 42, "#ff8080", 6)
