class_name Boneco3D
extends Node3D
## Boneco 3D (corpo base masculino ou feminino) trazido do kael.js via glTF.
## Aplica o cel-shading e o contorno, e anima as juntas com a mesma lógica do posar() do three.js.

const TOON := preload("res://shaders/toon.gdshader")
const CONTORNO := preload("res://shaders/contorno.gdshader")
const MODELOS := {
	"kael": preload("res://assets/personagens/kael.glb"),
	"lyra": preload("res://assets/personagens/lyra.glb"),
	"oren": preload("res://assets/personagens/oren.glb"),
}
const FECHADOS := {
	"kael": preload("res://assets/personagens/kael_olhos_fechados.png"),
	"lyra": preload("res://assets/personagens/lyra_olhos_fechados.png"),
	"oren": preload("res://assets/personagens/oren_olhos_fechados.png"),
}
# tinta da sombra por tipo de material (a cor base é multiplicada por ela na parte sombreada)
const TINTA_TECIDO := Color(0.56, 0.54, 0.84)
const TINTA_PELE := Color(0.90, 0.66, 0.72)
const TINTA_CABELO := Color(0.66, 0.60, 0.86)
const TINTA_MADEIRA := Color(0.62, 0.48, 0.62)
const PELE := ["pele", "orelha", "pescoco", "rosto"]
const CABELO := ["cabelo", "calota", "mecha", "cabeloLiso"]
const QY := 0.6
const DUR := [0.32, 0.32, 0.54]      # estado "atk" (menus): duração e instante do acerto de cada corte
const ACERTO := [0.1, 0.1, 0.18]

var nome := "kael"
var corpo := "m"
var arma := "espada"   # espada (com escudo), arco ou cajado: versões de madeira, a arma base de cada classe
# ---- estado da animação (quem usa o boneco preenche) ----
var estado := "idle"   # idle, run, ar, dor, livre, golpe (e "atk", o corte antigo, para as telas de menu)
var vy := 0.0          # > 0 subindo
var passo := 0         # estado "atk": qual corte (0, 1 ou 2)
var t := 0.0           # estado "atk": segundos dentro do golpe
var vento := 0.0       # 0..1: velocidade horizontal (cabelo para trás)
var corrida := 0.0     # 0 andando, 1 correndo
var relogio := 0.0
var alvo := {}         # estado "livre": ângulos das juntas pedidos por quem usa
var taxa_livre := 30.0
# estado "golpe": linha do tempo antecipação -> golpe -> passagem -> recuperação (tempos em quadros de 1/60 s)
var g_pre := {}
var g_pos := {}
var g_t := 0.0
var g_hit := 5.0
var g_fim := 20.0
var g_rastro := ""     # "arma" ou "pe": deixa rastro de luz durante o golpe
var g_ant := 0.0
var estado_ant := ""
var rastro_livre := false     # rastro ligado fora da linha do tempo (giros)
var amostras := []     # pontos do rastro deste quadro: [base, ponta] no mundo do boneco
var olhos_fechados := false   # expressão: olhos fechados (dor)

var J := {}            # molas das juntas: posição
var V := {}            # molas das juntas: velocidade
var freq := 6.0        # frequência das molas (Hz) no estado atual
var amort := 0.85      # amortecimento (1 = sem passar do ponto; menor = passa e volta)
var fase_corrida := 0.0
var cab_a := 0.0       # cabelo: ângulo e velocidade (pêndulo com mola)
var cab_v := 0.0
var ponta_ant := Vector3.ZERO
var borrao := 0.0      # arma esticada na direção do golpe (smear)
var cena: Node3D
var N := {}            # juntas por nome
var rest_x := {}
var esc_arma := Vector3.ONE
var mat_rosto: ShaderMaterial
var mats := []           # materiais de cel-shading, para a luz dos braseiros
var tex_aberto: Texture2D
var piscar := 2.0
var olho_fechado := 0.0

func _init(n := "kael", c := "m", a := "espada") -> void:
	nome = n; corpo = c; arma = a

func _ready() -> void:
	cena = MODELOS[nome].instantiate()
	add_child(cena)
	for j in ["quadril", "tronco", "cabeca", "cabeloTras", "cabeloLongo", "ombroE", "cotoveloE", "maoE", "espadaBase",
			"ombroS", "cotoveloS", "maoS", "escudoBase", "coxaA", "joelhoA", "coxaB", "joelhoB"]:
		N[j] = cena.find_child(j, true, false)
		rest_x[j] = N[j].rotation.x
	N.peA = N.joelhoA.get_child(N.joelhoA.get_child_count() - 1)
	esc_arma = N.espadaBase.scale
	_materiais(cena)
	if arma != "espada":
		N.espadaBase.visible = false
		N.escudoBase.visible = false
		_arma_extra()

func _materiais(no: Node) -> void:
	for f in no.get_children():
		_materiais(f)
	if not no is MeshInstance3D:
		return
	var mi := no as MeshInstance3D
	if String(mi.name).begins_with("ct_"):
		var esp := float(String(mi.name).split("_")[1]) / 10000.0
		var mc := ShaderMaterial.new(); mc.shader = CONTORNO; mc.set_shader_parameter("esp", esp); mc.set_shader_parameter("escala", 2.2)
		# a linha leva a cor da peça que ela contorna, bem escura e puxada para o violeta
		var pai := mi.get_parent() as MeshInstance3D
		var mp = pai.mesh.surface_get_material(0) if pai else null
		if mp is StandardMaterial3D:
			mc.set_shader_parameter("cor", cor_contorno(mp.albedo_color))
		mi.material_override = mc
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		return
	var src = mi.mesh.surface_get_material(0)
	var m := ShaderMaterial.new(); m.shader = TOON
	var nm := String(src.resource_name) if src else ""
	if src is StandardMaterial3D:
		m.set_shader_parameter("cor", src.albedo_color)
		if src.albedo_texture:
			m.set_shader_parameter("tex", src.albedo_texture)
			m.set_shader_parameter("tem_tex", true)
			m.set_shader_parameter("uv_escala", Vector2(src.uv1_scale.x, src.uv1_scale.y))
			m.set_shader_parameter("uv_desloc", Vector2(src.uv1_offset.x, src.uv1_offset.y))
	_tons(m, nm)
	mats.append(m)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if nm == "rosto":
		mat_rosto = m
		tex_aberto = src.albedo_texture

## Cor da sombra de cada material: a sombra é a cor base multiplicada por esta tinta (nunca cinza).
func _tons(m: ShaderMaterial, nm: String) -> void:
	var tinta := TINTA_TECIDO
	if nm in PELE: tinta = TINTA_PELE
	elif nm in CABELO: tinta = TINTA_CABELO
	elif nm.begins_with("madeira") or nm == "escudoMadeira": tinta = TINTA_MADEIRA
	m.set_shader_parameter("tinta_sombra", tinta)
	m.set_shader_parameter("forca_aro", 0.22)
	if nm == "rosto": m.set_shader_parameter("rosto", 1.0)
	if nm == "cabelo" or nm == "mecha": m.set_shader_parameter("anel", 1.0)

static func cor_contorno(c: Color) -> Color:
	var h := c.h
	var tom := fposmod(lerp_angle(h * TAU, 0.72 * TAU, 0.35) / TAU, 1.0) if c.s > 0.05 else 0.72
	return Color.from_hsv(tom, clampf(c.s * 1.1 + 0.25, 0.0, 0.8), clampf(c.v * 0.28, 0.03, 0.2))

# ---------- armas base de madeira das outras classes ----------
func _mat(c: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new(); m.shader = TOON; m.set_shader_parameter("cor", c)
	_tons(m, "madeira"); mats.append(m); return m

## Luz quente do braseiro mais perto (direção no mundo do jogo; x já espelhado pelo lado do herói).
func luz_quente(dir: Vector3, forca: float) -> void:
	for m in mats:
		m.set_shader_parameter("luz_quente", dir)
		m.set_shader_parameter("forca_quente", forca * 0.45)

func _tubo(pts: PackedVector3Array, r0: float, r1: float, mat: ShaderMaterial, esp := 0.009) -> MeshInstance3D:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lados := 8
	var aneis := []
	for i in pts.size():
		var tng := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var a := tng.cross(Vector3(0, 0, 1)).normalized()
		if a.length() < 0.1: a = tng.cross(Vector3(1, 0, 0)).normalized()
		var b := tng.cross(a)
		var r: float = lerpf(r0, r1, float(i) / (pts.size() - 1))
		var anel := []
		for k in lados:
			var ang := TAU * k / lados
			anel.append([pts[i] + (a * cos(ang) + b * sin(ang)) * r, (a * cos(ang) + b * sin(ang))])
		aneis.append(anel)
	for i in pts.size() - 1:
		for k in lados:
			var k2 := (k + 1) % lados
			for v in [aneis[i][k], aneis[i + 1][k], aneis[i + 1][k2], aneis[i][k], aneis[i + 1][k2], aneis[i][k2]]:
				st.set_normal(v[1]); st.add_vertex(v[0])
	var mesh := st.commit()
	var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = mat
	var ct := MeshInstance3D.new(); ct.mesh = mesh
	var mc := ShaderMaterial.new(); mc.shader = CONTORNO; mc.set_shader_parameter("esp", esp); mc.set_shader_parameter("escala", 2.2); ct.material_override = mc
	mc.set_shader_parameter("cor", cor_contorno(mat.get_shader_parameter("cor")))
	mi.add_child(ct)
	return mi

func _arma_extra() -> void:
	var madeira := _mat(Color("#8a5a32"))
	var escura := _mat(Color("#4a3018"))
	var g := Node3D.new(); N.maoE.add_child(g); N.armaExtra = g
	if arma == "arco":
		# arco de madeira: duas pernas curvas saindo da empunhadura, com a corda
		var pts := PackedVector3Array()
		for i in 17:
			var k := (i / 16.0) * 2.0 - 1.0
			pts.append(Vector3(k * 0.5, 0.0, -0.13 * (1.0 - k * k) + 0.13))
		var arco := _tubo(pts, 0.022, 0.022, madeira)
		g.add_child(arco)
		g.add_child(_tubo(PackedVector3Array([Vector3(-0.5, 0, 0.13), Vector3(0.5, 0, 0.13)]), 0.004, 0.004, _mat(Color("#d8d0c0")), 0.002))
		g.add_child(_tubo(PackedVector3Array([Vector3(-0.07, 0, -0.005), Vector3(0.07, 0, -0.005)]), 0.03, 0.03, escura))
		g.rotation = Vector3(PI / 2, 0, 0)
	else:
		# cajado de madeira com a ponta enrolada
		var pts2 := PackedVector3Array()
		for i in 10:
			pts2.append(Vector3(-0.35 + i * 0.15, sin(i * 1.3) * 0.008, 0))
		g.add_child(_tubo(pts2, 0.024, 0.03, madeira))
		var nodo := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.06; sm.height = 0.11; nodo.mesh = sm
		nodo.material_override = escura; nodo.position = Vector3(1.05, 0, 0); g.add_child(nodo)

# ---------- animação ----------
# Cada junta é uma mola que persegue o ângulo alvo: assim o movimento acelera, passa um pouco do ponto e assenta
# (antecipação, passagem e ação sobreposta saem de graça). Ver cofre: Arte/Pesquisa - Arte e Animação.
#
# Juntas (radianos): S/E = ombro e cotovelo da arma, W = pulso da arma, Sx = braço da arma abrindo para a câmera,
# S2/E2/S2x = braço do escudo, cA/jA e cB/jB = coxa e joelho, inc = tronco (negativo inclina para a frente),
# tor = torção do tronco, cab/cabY = cabeça, sobe = altura do quadril, gira = corpo todo virando para a câmera,
# rola = corpo todo girando (cambalhota), dx = avanço do corpo, est = esticar (+) ou amassar (-) conservando o volume.
const BASE := {"S": 0.3, "E": 0.5, "W": -1.3, "Sx": 0.0, "S2": 0.35, "E2": 1.25, "S2x": 0.0, "cA": 0.28, "jA": -0.2, "cB": -0.3, "jB": -0.12,
	"inc": -0.03, "tor": 0.12, "sobe": -0.03, "cab": 0.0, "cabY": 0.0, "gira": 0.0, "rola": 0.0, "dx": 0.0, "est": 0.0}
## Base das poses de combate (golpes e poses "livres"): pernas afastadas, joelhos dobrados.
const COMBATE := {"cA": 0.5, "jA": -0.4, "cB": -0.5, "jB": -0.2}
## Juntas da ponta atrasam um pouco em relação ao tronco (ação sobreposta).
const ATRASO := {"W": 0.8, "E": 0.92, "E2": 0.9, "S2": 0.92, "cab": 0.75, "cabY": 0.6}
## Juntas com mola própria, igual em todos os estados: [frequência Hz, amortecimento].
const FIXO := {"est": [4.6, 0.42]}

static func suave(k: float) -> float:
	k = clampf(k, 0.0, 1.0); return 1.0 - pow(1.0 - k, 3.0)

static func mistura(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var r := {}
	for kk in BASE:
		var va: float = a.get(kk, BASE[kk])
		var vb: float = b.get(kk, BASE[kk])
		r[kk] = va + (vb - va) * k
	return r

## Pose completa a partir de uma pose parcial: o que ela não define vem da base de combate.
static func pose_combate(d: Dictionary) -> Dictionary:
	var r := BASE.duplicate()
	r.merge(COMBATE, true)
	r.merge(d, true)
	return r

## Empurrão numa mola (ex.: amassar ao pousar, tranco ao levar golpe).
func impulso(junta: String, v: float) -> void:
	if V.has(junta): V[junta] += v

## Pula direto para a pose alvo, sem transição (ao criar o boneco ou trocar de tela).
func encaixar() -> void:
	J.clear()
	posar(1.0 / 60.0)

func posar(dt: float) -> void:
	amostras.clear()
	if dt <= 0.0:
		return
	if J.is_empty():
		var a0 := _alvo(0.0)
		J = a0.duplicate()
		for kk in a0: V[kk] = 0.0
		cab_a = 0.0; cab_v = 0.0
	# durante o golpe o boneco anda em passos menores, para o rastro da arma sair redondo
	var passos := 4 if _no_golpe() else 1
	var h := dt / passos
	for i in passos:
		relogio += h
		var A := _alvo(h, float(i + 1) / passos)
		_molas(A, h)
		_aplicar(h)
		if _rastro_ligado():
			amostras.append(_pontos_rastro())
	_rosto(dt)
	estado_ant = estado

func _no_golpe() -> bool:
	return (estado == "golpe" and g_t > g_hit - 6.0 and g_t < g_hit + 6.0) or rastro_livre

func _rastro_ligado() -> bool:
	return rastro_livre or (estado == "golpe" and g_rastro != "" and g_t >= g_hit - _balanco() and g_t <= g_hit + 2.0)

func _balanco() -> float:
	return 2.5 if g_hit < 8.0 else 3.5

## Pose alvo deste instante. `sub` (0..1) é a fração do quadro já percorrida nos passos menores.
func _alvo(dt: float, sub := 0.0) -> Dictionary:
	var r := relogio
	var A := BASE.duplicate()
	freq = 5.0; amort = 0.85
	match estado:
		"idle":
			var b := sin(r * 1.9)                 # respiração
			var peso := sin(r * 0.55)             # troca de peso, bem lenta
			A.sobe += b * 0.012 + absf(peso) * -0.008
			A.S += b * 0.035; A.E += b * 0.05; A.S2 += b * 0.025; A.E2 += -b * 0.03
			A.inc += b * 0.012; A.cab = -b * 0.02; A.tor += peso * 0.05
			A.cabY = sin(r * 0.31) * 0.12
			if corpo == "f":
				A.cA = 0.1 + peso * 0.03; A.cB = -0.1 + peso * 0.03; A.jA = -0.06; A.jB = -0.04; A.tor = 0.06 + peso * 0.05
			else:
				A.cA = 0.34; A.cB = -0.36
			freq = 3.2; amort = 0.8
		"run":
			fase_corrida += dt * lerpf(11.5, 14.5, corrida)
			var p := fase_corrida
			var s := sin(p)
			var c := cos(p)
			var k := corrida
			A.cA = s * lerpf(0.85, 1.12, k) + 0.12; A.cB = -s * lerpf(0.85, 1.12, k) + 0.12
			A.jA = -maxf(0.0, c) * lerpf(1.25, 1.6, k) - 0.22; A.jB = -maxf(0.0, -c) * lerpf(1.25, 1.6, k) - 0.22
			# braços em contra-balanço; correndo, o braço da arma fica para trás
			A.S = lerpf(-0.35 - s * 0.45, -0.95 - s * 0.18, k); A.E = lerpf(0.75 + s * 0.2, 0.3, k); A.W = lerpf(-2.2, -2.75, k)
			A.S2 = lerpf(0.45 + s * 0.5, 0.75 + s * 0.3, k); A.E2 = lerpf(1.35, 1.5, k)
			A.inc = lerpf(-0.2, -0.38, k); A.tor = s * lerpf(0.2, 0.28, k); A.gira = -s * 0.07
			A.sobe = absf(c) * 0.06 - lerpf(0.06, 0.09, k); A.cab = lerpf(0.12, 0.26, k); A.est = absf(s) * 0.03
			freq = 9.0; amort = 0.8
		"ar":
			# subindo: estica, joelho da frente alto; ápice: encolhe; caindo: braços sobem, pernas soltas
			var sub_k := clampf(vy / 3.5, -1.0, 1.0)
			var apice := 1.0 - absf(sub_k)
			if sub_k > 0.0:
				A.cA = lerpf(0.9, 1.25, apice); A.jA = lerpf(-1.3, -1.7, apice); A.cB = lerpf(-0.45, 0.35, apice); A.jB = lerpf(-0.35, -1.25, apice)
				A.S = lerpf(-0.75, 0.2, apice); A.E = 0.45; A.W = -2.2; A.S2 = lerpf(0.2, 0.9, apice); A.E2 = 1.0
				A.inc = lerpf(-0.14, -0.05, apice); A.cab = lerpf(-0.12, 0.05, apice); A.est = 0.1 * sub_k
			else:
				var q := -sub_k
				A.cA = lerpf(1.25, 0.5, q); A.jA = lerpf(-1.7, -0.65, q); A.cB = lerpf(0.35, -0.3, q); A.jB = lerpf(-1.25, -0.35, q)
				A.S = lerpf(0.2, 2.2, q); A.E = 0.35; A.W = lerpf(-2.2, -1.2, q); A.S2 = lerpf(0.9, 1.9, q); A.E2 = lerpf(1.0, 0.6, q)
				A.inc = lerpf(-0.05, 0.1, q); A.cab = lerpf(0.05, 0.18, q); A.est = 0.07 * q
			A.sobe = 0.0
			freq = 5.5; amort = 0.75
		"dor":
			A.inc = 0.42; A.tor = -0.3; A.S = 1.3; A.E = 0.9; A.Sx = -0.3; A.S2 = 1.2; A.E2 = 0.6; A.cA = 0.2; A.cB = -0.55; A.jA = -0.6; A.jB = -0.2
			A.cab = -0.35; A.sobe = -0.08; A.gira = -0.25
			freq = 9.0; amort = 0.5
		"livre":
			A.merge(COMBATE, true)
			A.merge(alvo, true)
			freq = clampf(taxa_livre / 6.0, 1.5, 11.0); amort = 0.72
		"golpe", "atk":
			A = _alvo_golpe(dt, sub)
	return A

## Linha do tempo do golpe: antecipação -> golpe acelerando até o contato -> passagem segurada -> recuperação.
func _alvo_golpe(_dt: float, sub: float) -> Dictionary:
	var tg := g_t - 1.0 + sub     # g_t é o quadro do golpe; `sub` anda dentro do quadro
	if estado == "atk":
		# compatibilidade com as telas de menu: corte 0, 1 ou 2 com o tempo em segundos
		var c: Array = Poses.CORTES[passo % Poses.CORTES.size()]
		g_pre = Poses.P[c[0]]; g_pos = Poses.P[c[1]]; g_hit = ACERTO[passo] * 60.0; g_fim = DUR[passo] * 60.0; g_t = t * 60.0; g_rastro = ""
		tg = g_t
	var pre := pose_combate(g_pre)
	var pos := pose_combate(g_pos)
	var bal := _balanco()
	var ini := g_hit - bal - 0.5     # as molas atrasam um pouco: o golpe chega logo antes do acerto
	var fim_passagem := g_hit + (7.0 if g_hit < 8.0 else 10.0)
	if g_t < g_ant or estado != estado_ant:
		# começo do golpe: salta quase direto para a antecipação (pose "estalada", como na animação desenhada)
		for kk in pre:
			if kk != "est" and J.has(kk):
				J[kk] = lerpf(J[kk], pre[kk], 0.6); V[kk] = 0.0
	g_ant = g_t
	if tg < ini:
		freq = 12.0; amort = 0.85
		return pre
	if tg < g_hit - 0.5:
		var u := (tg - ini) / bal
		freq = 14.0; amort = 0.62
		return mistura(pre, pos, u * u)
	if tg < fim_passagem:
		freq = 8.5; amort = 0.46
		return pos
	var k := clampf((tg - fim_passagem) / maxf(6.0, g_fim - fim_passagem), 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	freq = 5.0; amort = 0.85
	return mistura(pos, pose_combate(Poses.P.pronto), k * 0.85)

func _molas(A: Dictionary, dt: float) -> void:
	var n := 3
	var h := dt / n
	for kk in A:
		var f: float = freq * ATRASO.get(kk, 1.0)
		var z: float = amort
		if FIXO.has(kk):
			f = FIXO[kk][0]; z = FIXO[kk][1]
		var w := TAU * f
		var x: float = J.get(kk, A[kk])
		var v: float = V.get(kk, 0.0)
		var g: float = A[kk]
		for i in n:
			v += (w * w * (g - x) - 2.0 * z * w * v) * h
			x += v * h
		J[kk] = x; V[kk] = v
	# cabelo: pêndulo que tenta ficar a prumo; a cabeça e a velocidade do herói é que o balançam
	var prumo: float = -(J.inc * 0.4 + J.cab) * 0.8 - vento * 0.75 + clampf(-vy * 0.06, -0.5, 0.35)
	var wc := TAU * 2.3
	for i in n:
		cab_v += (wc * wc * (prumo - cab_a) - 2.0 * 0.33 * wc * cab_v) * h
		cab_a += cab_v * h
	cab_a = clampf(cab_a, -1.5, 0.9)

func _aplicar(dt: float) -> void:
	var r := relogio
	# corpo inteiro: esticar/amassar com pivô nos pés, cambalhota em volta do quadril, giro e avanço
	var e := 1.0 + clampf(J.est, -0.35, 0.4)
	var lado := 1.0 / sqrt(e)
	var giro := Basis(Vector3.UP, J.gira)
	var rolo := Basis(Vector3.BACK, J.rola)
	var centro := Vector3(0, QY * e, 0)
	cena.transform = Transform3D(giro * rolo * Basis.from_scale(Vector3(lado, e, lado)), Vector3(J.dx, 0, 0) + giro * (centro - rolo * centro))
	N.quadril.position.y = QY + J.sobe * 0.6
	_rot(N.tronco, 0, J.tor, J.inc)
	_rot(N.cabeca, 0, -J.tor * 0.7 + J.cabY, -J.inc * 0.6 + J.cab)
	_rot(N.cabeloTras, 0, 0, cab_a * 0.2 + sin(r * 1.7 + 0.6) * 0.012)
	_rot(N.cabeloLongo, 0, 0, -0.1 + cab_a + sin(r * 1.7) * 0.03 + sin(r * 7.0) * 0.05 * vento)
	_rot(N.ombroE, rest_x.ombroE + J.Sx, 0, J.S); _rot(N.cotoveloE, 0, 0, J.E)
	N.espadaBase.scale = esc_arma * Vector3(1.0 + borrao, 1.0, 1.0)
	_rot(N.espadaBase, 0, 0, J.W)
	if N.has("armaExtra"):
		var w: Node3D = N.armaExtra
		w.scale = Vector3(1.0 + borrao, 1.0, 1.0)
		if arma == "arco":
			w.scale = Vector3.ONE
			w.rotation = Vector3(PI / 2, 0, J.W + 1.3)
		else:
			w.rotation = Vector3(0, 0, J.W)
	_rot(N.ombroS, rest_x.ombroS - J.S2x, 0, J.S2); _rot(N.cotoveloS, 0, 0, J.E2)
	_rot(N.escudoBase, 0, 0, -(J.S2 + J.E2) - J.inc)
	_rot(N.coxaA, rest_x.coxaA, 0, J.cA); _rot(N.joelhoA, 0, 0, J.jA)
	_rot(N.coxaB, rest_x.coxaB, 0, J.cB); _rot(N.joelhoB, 0, 0, J.jB)
	# borrão (smear): a arma estica na direção do movimento quando a ponta passa muito rápido
	var ponta := ponta_arma()
	var vel := (ponta - ponta_ant).length() / maxf(dt, 0.0001)
	ponta_ant = ponta
	var alvo_b := clampf((vel - 9.0) / 30.0, 0.0, 0.45) if estado in ["golpe", "atk"] else 0.0
	borrao += (alvo_b - borrao) * minf(1.0, dt * 40.0)

## Ponta e base da arma (ou do pé, para chutes) no mundo do boneco.
func ponta_arma() -> Vector3:
	if arma == "espada": return N.espadaBase.to_global(Vector3(1.0, 0, 0))
	if arma == "cajado": return (N.armaExtra as Node3D).to_global(Vector3(1.08, 0, 0))
	return (N.maoE as Node3D).global_position

func _pontos_rastro() -> Array:
	if g_rastro == "pe":
		return [(N.joelhoA as Node3D).global_position, (N.peA as Node3D).to_global(Vector3(0.16, 0, 0))]
	if arma == "espada":
		return [N.espadaBase.to_global(Vector3(0.22, 0, 0)), N.espadaBase.to_global(Vector3(1.02, 0, 0))]
	if arma == "cajado":
		return [(N.armaExtra as Node3D).to_global(Vector3(0.45, 0, 0)), (N.armaExtra as Node3D).to_global(Vector3(1.12, 0, 0))]
	return [(N.cotoveloE as Node3D).global_position, (N.maoE as Node3D).global_position]

func _rosto(dt: float) -> void:
	piscar -= dt
	if piscar <= 0:
		olho_fechado = 0.11; piscar = 2.5 + randf() * 3.0
	if olho_fechado > 0:
		olho_fechado -= dt
	if mat_rosto:
		mat_rosto.set_shader_parameter("tex", FECHADOS[nome] if (olho_fechado > 0 or olhos_fechados) else tex_aberto)

## Rotação na ordem do three.js (XYZ: matriz = Rx * Ry * Rz), mantendo a escala do nó.
func _rot(no: Node3D, x: float, y: float, z: float) -> void:
	no.basis = Basis(Vector3.RIGHT, x) * Basis(Vector3.UP, y) * Basis(Vector3.BACK, z) * Basis.from_scale(no.scale)
