class_name Gfx
extends RefCounted
## Desenho provisório (placeholder) feito em código. Será trocado pelos sprites do PixelLab.

static func col(v, a := 1.0) -> Color:
	var c: Color = v if v is Color else Color(v)
	c.a *= a
	return c

static func rect(c: CanvasItem, x: float, y: float, w: float, h: float, v, a := 1.0) -> void:
	c.draw_rect(Rect2(x, y, w, h), col(v, a))

static func tri(c: CanvasItem, a: Vector2, b: Vector2, d: Vector2, v, al := 1.0) -> void:
	c.draw_colored_polygon(PackedVector2Array([a, b, d]), col(v, al))

static func text(c: CanvasItem, s: String, x: float, y: float, v = "#ffffff", size := 8, align := 0, a := 1.0) -> void:
	var font: Font = ThemeDB.fallback_font
	var tw: float = font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var ox := x
	if align == 1:
		ox = x - tw / 2.0
	elif align == 2:
		ox = x - tw
	var by := y + size * 0.35
	var sh := Color(0, 0, 0, a)
	for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		c.draw_string(font, Vector2(ox, by) + d * 0.7, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, sh)
	c.draw_string(font, Vector2(ox, by), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col(v, a))

static func slash(c: CanvasItem, cx: float, cy: float, f: int, r: float, s: int, k: float, v) -> void:
	c.draw_set_transform(Vector2(cx, cy), 0.0, Vector2(f, 1))
	if s == 1:
		c.draw_arc(Vector2.ZERO, r, 0.9, -1.2, 12, col(v, 1.0 - k), 3.0 * (1.0 - k) + 1.0)
	else:
		c.draw_arc(Vector2.ZERO, r, -1.3, 1.0, 12, col(v, 1.0 - k), 3.0 * (1.0 - k) + 1.0)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

## Desenha um herói com os pés na origem de `base`. `s` = {state, t, step, skill, anim, on_ground}
static func hero(c: CanvasItem, d: Dictionary, s: Dictionary, base: Transform2D) -> void:
	var id: String = d.id
	var st: String = s.state
	var t: float = s.get("t", 0)
	var anim: float = s.anim
	var air: bool = not s.on_ground
	var run := sin(anim * 0.3) if st == "run" else 0.0
	var l1: int = -2 if air else int(roundf(run * 3))
	var l2: int = 2 if air else -int(roundf(run * 3))
	var bob: int = 1 if (st == "idle" and sin(anim * 0.08) > 0) else 0
	c.draw_set_transform_matrix(base)
	if id == "guardiao":
		rect(c, -8, -18 + bob, 4, 10, d.trim); rect(c, -7, -17 + bob, 2, 8, "#b38f2a")
	if id == "cacadora":
		rect(c, -8, -20 + bob, 3, 9, "#7a4f2a"); rect(c, -8, -22 + bob, 1, 3, "#dddddd"); rect(c, -6, -22 + bob, 1, 3, "#dddddd")
	if id != "arcanista":
		rect(c, -4 + l1, -8, 3, 8, "#2b2b3a"); rect(c, 1 + l2, -8, 3, 8, "#2b2b3a")
		rect(c, -4 + l1, -2, 4, 2, "#4a2f1d"); rect(c, 1 + l2, -2, 4, 2, "#4a2f1d")
	var bb := base * Transform2D(0.0, Vector2(0, bob))
	c.draw_set_transform_matrix(bb)
	if id == "arcanista":
		rect(c, -5, -16, 10, 14, d.body); rect(c, -6, -4, 12, 4, d.body); rect(c, -6, -1, 12, 1, d.dark)
		rect(c, -5, -10, 10, 1, d.trim); rect(c, -1 + l1 / 2, 0, 3, 1, "#2b2b3a")
	else:
		rect(c, -5, -17, 10, 10, d.body); rect(c, -5, -17, 2, 10, d.dark); rect(c, -5, -10, 10, 2, d.trim)
	rect(c, -4, -24, 8, 7, "#f1c27d"); rect(c, 2, -22, 1, 2, "#1a1a22")
	match id:
		"guardiao":
			rect(c, -4, -26, 8, 3, d.hair); rect(c, -5, -25, 2, 5, d.hair); rect(c, -4, -27, 6, 1, d.hair)
		"cacadora":
			rect(c, -5, -27, 9, 4, d.dark); rect(c, -5, -24, 2, 6, d.dark); rect(c, -8, -22, 3, 7, d.hair); rect(c, 3, -26, 2, 2, d.dark)
		"arcanista":
			tri(c, Vector2(-6, -25), Vector2(7, -25), Vector2(-4, -36), d.body)
			rect(c, -7, -26, 14, 2, d.dark); rect(c, -2, -18, 5, 4, d.hair); rect(c, -4, -31, 3, 1, d.trim)
	var step: int = s.get("step", 0)
	var sk: int = s.get("skill", -1)
	if id == "guardiao":
		var ang := 0.35
		if st == "attack":
			var k := clampf(t / float(GameData.ATK_HIT[step]), 0.0, 1.0)
			ang = (2.2 - k * 3.6) if step == 1 else (-2.0 + k * 3.8)
		elif st == "skill" and sk == 1:
			ang = t * 0.7
		elif st == "skill" and sk == 2:
			ang = 1.8 - clampf(t / 8.0, 0.0, 1.0) * 3.2
		elif st == "skill" and sk == 0:
			ang = 1.4
		c.draw_set_transform_matrix(bb * Transform2D(ang, Vector2(3, -13)))
		rect(c, -1, -16, 3, 15, "#dfe5ee"); rect(c, 0, -16, 1, 15, "#ffffff"); rect(c, -3, -1, 7, 2, d.trim); rect(c, -1, 1, 3, 3, "#5a3b28")
		c.draw_set_transform_matrix(bb)
		rect(c, 2, -15, 3, 6, d.dark)
		if st == "skill" and sk == 0:
			rect(c, 5, -20, 5, 14, d.trim); rect(c, 6, -19, 3, 12, "#b38f2a")
	elif id == "cacadora":
		var pull := 3.0 if ((st == "attack" and t < GameData.ATK_HIT[step]) or (st == "skill" and t < 8)) else 0.0
		c.draw_arc(Vector2(3, -13), 9, -1.25, 1.25, 10, col("#8b5a2b"), 2.0)
		c.draw_polyline(PackedVector2Array([Vector2(6.1, -21.6), Vector2(6.1 - pull * 1.5, -13), Vector2(6.1, -4.4)]), col("#eeeeee"), 1.0)
		if pull > 0:
			rect(c, 1, -14, 12, 1, "#dddddd")
		rect(c, 2, -15, 4, 3, "#f1c27d")
	else:
		var ang2 := 0.15
		if st == "attack" and step < 2:
			var k2 := clampf(t / float(GameData.ATK_HIT[step]), 0.0, 1.0)
			ang2 = -1.2 + k2 * 2.4
		c.draw_set_transform_matrix(bb * Transform2D(ang2, Vector2(5, -12)))
		rect(c, -1, -14, 2, 26, "#7a4f2a"); rect(c, -2, -17, 4, 4, d.trim)
		if st == "skill" or (st == "attack" and step == 2):
			c.draw_circle(Vector2(0, -15), 5, col(d.trim, 0.5 + 0.3 * sin(t)))
		c.draw_set_transform_matrix(bb)
		rect(c, 3, -15, 3, 5, d.dark)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)
