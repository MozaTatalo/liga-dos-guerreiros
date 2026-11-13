extends Node2D
## Céu e montanhas com parallax, desenhados em coordenadas de tela.

var cam_x := 0.0
var mt := []
var hl := []
var tr := []

func _ready() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 11
	var x := -40.0
	while x < 1400:
		mt.append(Vector2(x, 95 + r.randf() * 55)); x += 34
	x = -40.0
	while x < 2400:
		hl.append(Vector2(x, 165 + r.randf() * 30)); x += 26
	x = 0.0
	while x < 2400:
		tr.append(Vector2(x, r.randf())); x += r.randi_range(30, 70)

func _poly(pts: Array, off: float, c: String) -> void:
	var arr := PackedVector2Array()
	arr.append(Vector2(pts[0].x + off, GameData.H))
	for q in pts:
		arr.append(Vector2(roundf(q.x + off), roundf(q.y)))
	arr.append(Vector2(pts[pts.size() - 1].x + off, GameData.H))
	draw_colored_polygon(arr, Gfx.col(c))

func _draw() -> void:
	var boss := clampf((cam_x - 2050) / 250.0, 0, 1)
	var top := Color("#1d2b53").lerp(Color("#1a0f24"), boss)
	var mid := Color("#7e4f7a").lerp(Color("#5b1d2a"), boss)
	var bot := Color("#ff9e7a").lerp(Color("#a0442c"), boss)
	var bands := 54
	for i in bands:
		var k := i / float(bands - 1)
		var c := top.lerp(mid, k / 0.6) if k < 0.6 else mid.lerp(bot, (k - 0.6) / 0.4)
		draw_rect(Rect2(0, i * GameData.H / bands, GameData.W, GameData.H / bands + 1), c)
	draw_circle(Vector2(380, 70), 18, Gfx.col("#fff2c6", 0.9))
	_poly(mt, -cam_x * 0.15, "#3b3563")
	_poly(hl, -cam_x * 0.4, "#2a2a4a")
	for t in tr:
		var tx := roundf(t.x - cam_x * 0.4)
		if tx < -20 or tx > GameData.W + 20:
			continue
		var hy: float = 180 + t.y * 12
		Gfx.rect(self, tx, hy, 3, 20, "#1f1d33")
		Gfx.tri(self, Vector2(tx - 8, hy + 6), Vector2(tx + 1, hy - 16), Vector2(tx + 11, hy + 6), "#24233f")
