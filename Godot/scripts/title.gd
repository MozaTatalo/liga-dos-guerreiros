extends Node2D
## Tela de título e seleção de personagem.

signal start_game(class_indexes: Array)

var sel := 0
var bg
var t := 0
var views := []

func _ready() -> void:
	for i in 3:
		var v := HeroView.new(GameData.CLASSES[i])
		v.position = Vector2(GameData.W / 2 - 150 + i * 100 + 45, 56 + 78)
		v.scale = Vector2(1.4, 1.4)
		add_child(v)
		views.append(v)

func _physics_process(_d: float) -> void:
	t += 1
	if Input.is_action_just_pressed("p1_left"): sel = (sel + 2) % 3
	if Input.is_action_just_pressed("p1_right"): sel = (sel + 1) % 3
	if Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("p1_attack"):
		start_game.emit([sel])
		return
	bg.cam_x = fmod(t * 0.4, 1200.0)
	bg.queue_redraw()
	for i in 3:
		views[i].boneco.estado = "run" if i == sel else "idle"
		views[i].animar(1.0 / 60.0)
	queue_redraw()

func _draw() -> void:
	var W := GameData.W
	Gfx.rect(self, 0, 0, W, GameData.H, "#050514", 0.45)
	Gfx.text(self, "LIGA DOS GUERREIROS", W / 2, 26, "#ffd23f", 22, 1)
	Gfx.text(self, "protótipo Godot · Fase 1", W / 2, 44, "#cfd3e6", 7, 1)
	for i in 3:
		var c: Dictionary = GameData.CLASSES[i]
		var x := W / 2 - 150 + i * 100
		var y := 56.0
		var on := i == sel
		Gfx.rect(self, x, y, 90, 96, "#3c326e" if on else "#0f0f23", 0.9 if on else 0.8)
		if on:
			Gfx.rect(self, x, y, 90, 2, c.trim); Gfx.rect(self, x, y + 94, 90, 2, c.trim)
		Gfx.text(self, c.name, x + 45, y + 84, "#ffffff", 8, 1)
		Gfx.text(self, c.cls, x + 45, y + 92, c.trim, 6, 1)
	var d: Dictionary = GameData.CLASSES[sel]
	Gfx.rect(self, W / 2 - 150, 158, 290, 96, "#0f0f23", 0.85)
	Gfx.text(self, "%s — %s" % [d.name, d.cls], W / 2 - 142, 167, "#ffffff", 9)
	Gfx.text(self, "Arma: %s  ·  %s" % [d.weapon, d.role], W / 2 - 142, 179, d.trim, 6)
	Gfx.text(self, d.desc[0], W / 2 - 142, 190, "#cfd3e6", 6)
	Gfx.text(self, d.desc[1], W / 2 - 142, 198, "#cfd3e6", 6)
	for i in 3:
		var s: Dictionary = d.skills[i]
		Gfx.text(self, "%s  %s  (%d MP)" % ["ASD"[i], s.n, s.mp], W / 2 - 142, 211 + i * 9, s.c, 6)
	Gfx.text(self, "Vida %d  ·  Mana %d" % [d.hp, d.mp], W / 2 + 132, 211, "#cfd3e6", 6, 2)
	if t % 60 < 40:
		Gfx.text(self, "← → escolher  ·  Enter ou Z para começar", W / 2, 264, "#ffffff", 7, 1)
