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
# degraus de luz do kael.js (GRAD, GRAD_PELE, GRAD_CABELO)
const GRAD := [Vector4(70, 135, 200, 255) / 255.0, 4]
const GRAD_PELE := [Vector4(172, 228, 255, 255) / 255.0, 3]
const GRAD_CABELO := [Vector4(150, 215, 255, 255) / 255.0, 3]
const PELE := ["pele", "orelha", "pescoco", "rosto"]
const CABELO := ["cabelo", "calota", "mecha", "cabeloLiso"]
const QY := 0.6
const DUR := [0.32, 0.32, 0.54]
const ACERTO := [0.1, 0.1, 0.18]
const ARCO := [[2.75, 0.45], [-0.55, 2.55], [3.15, 0.1]]

var nome := "kael"
var corpo := "m"
var arma := "espada"   # espada (com escudo), arco ou cajado: versões de madeira, a arma base de cada classe
# estado da animação (quem usa o boneco preenche)
var estado := "idle"   # idle, run, ar, atk, dor
var vy := 0.0          # > 0 subindo
var passo := 0
var t := 0.0           # segundos dentro do golpe
var vento := 0.0
var relogio := 0.0
var alvo := {}         # estado "livre": ângulos das juntas pedidos por quem usa (S, E, W, S2, E2, cA, jA, cB, jB, inc, tor, sobe, cab)
var taxa_livre := 30.0

var J := {}
var N := {}            # juntas por nome
var rest_x := {}
var mat_rosto: ShaderMaterial
var mats := []           # materiais de cel-shading, para a luz dos braseiros
var tex_aberto: Texture2D
var piscar := 2.0
var olho_fechado := 0.0

func _init(n := "kael", c := "m", a := "espada") -> void:
	nome = n; corpo = c; arma = a

func _ready() -> void:
	var cena: Node3D = MODELOS[nome].instantiate()
	add_child(cena)
	for j in ["quadril", "tronco", "cabeca", "cabeloTras", "cabeloLongo", "ombroE", "cotoveloE", "maoE", "espadaBase",
			"ombroS", "cotoveloS", "maoS", "escudoBase", "coxaA", "joelhoA", "coxaB", "joelhoB"]:
		N[j] = cena.find_child(j, true, false)
		rest_x[j] = N[j].rotation.x
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
		var mc := ShaderMaterial.new(); mc.shader = CONTORNO; mc.set_shader_parameter("esp", esp); mc.set_shader_parameter("escala", 2.4)
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
	var g = GRAD_PELE if nm in PELE else (GRAD_CABELO if nm in CABELO else GRAD)
	m.set_shader_parameter("degraus", g[0])
	m.set_shader_parameter("n_degraus", g[1])
	m.set_shader_parameter("forca_aro", 0.18)
	mats.append(m)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if nm == "rosto":
		mat_rosto = m
		tex_aberto = src.albedo_texture

# ---------- armas base de madeira das outras classes ----------
func _mat(c: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new(); m.shader = TOON; m.set_shader_parameter("cor", c)
	m.set_shader_parameter("forca_aro", 0.18); mats.append(m); return m

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
	var mc := ShaderMaterial.new(); mc.shader = CONTORNO; mc.set_shader_parameter("esp", esp); mc.set_shader_parameter("escala", 2.4); ct.material_override = mc
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

# ---------- animação: mesma lógica do posar() do kael.js ----------
static func suave(k: float) -> float:
	k = clampf(k, 0.0, 1.0); return 1.0 - pow(1.0 - k, 3.0)

func posar(dt: float) -> void:
	relogio += dt
	var r := relogio
	var e := estado
	var A := {"S": 0.3, "E": 0.5, "W": -1.3, "S2": 0.35, "E2": 1.25, "cA": 0.28, "jA": -0.2, "cB": -0.3, "jB": -0.12, "inc": -0.03, "tor": 0.12, "sobe": -0.03, "cab": 0.0}
	var taxa := 16.0
	if e == "idle":
		var b := sin(r * 2.2)
		A.sobe += b * 0.012; A.S += b * 0.03; A.E += b * 0.04; A.S2 += b * 0.02
		if corpo == "f":
			A.cA = 0.1; A.cB = -0.1; A.jA = -0.06; A.jB = -0.04; A.tor = 0.06
		else:
			A.cA = 0.34; A.cB = -0.36
	elif e == "run":
		var p := r * 12.5
		var s := sin(p)
		var c := cos(p)
		A.cA = s * 0.95 + 0.1; A.cB = -s * 0.95 + 0.1
		A.jA = -maxf(0, c) * 1.35 - 0.2; A.jB = -maxf(0, -c) * 1.35 - 0.2
		A.S = -0.55 + s * 0.12; A.E = 0.35; A.W = -2.55; A.S2 = 0.5 + s * 0.2; A.E2 = 1.3
		A.inc = -0.22; A.tor = s * 0.14; A.sobe = absf(c) * 0.055 - 0.06; A.cab = 0.12; taxa = 26.0
	elif e == "ar":
		var sub := vy > 0
		A.cA = 0.95 if sub else 0.4; A.jA = -1.35 if sub else -0.55; A.cB = -0.25 if sub else -0.35; A.jB = -0.5 if sub else -0.25
		A.S = -0.7 if sub else 2.3; A.E = 0.4; A.W = -2.2 if sub else -1.2; A.S2 = 0.8 if sub else 1.4; A.E2 = 0.8
		A.inc = -0.1 if sub else 0.08; A.sobe = 0.0; taxa = 14.0
	elif e == "dor":
		A.inc = 0.35; A.tor = -0.2; A.S = 1.2; A.E = 0.9; A.S2 = 1.1; A.E2 = 0.6; A.cA = 0.1; A.cB = -0.5; A.jA = -0.5; A.cab = -0.25; taxa = 22.0
	elif e == "livre":
		A.cA = 0.5; A.jA = -0.4; A.cB = -0.5; A.jB = -0.2
		for kk in alvo: A[kk] = alvo[kk]
		taxa = taxa_livre
	else:
		var n := passo
		var k := suave(t / ACERTO[n])
		var ar: Array = ARCO[n]
		var volta := maxf(0, (t - ACERTO[n]) / (DUR[n] - ACERTO[n]))
		A.S = ar[0] + (ar[1] - ar[0]) * k + (1.0 if ar[1] > ar[0] else -1.0) * volta * 0.1; A.E = 0.1; A.W = -1.38
		A.inc = (0.16 if n == 1 else -0.28) * k; A.tor = (-0.6 if n == 1 else 0.6) * (k - 0.45)
		A.S2 = -0.45; A.E2 = 1.0; A.cA = 0.62; A.jA = -0.45; A.cB = -0.55; A.jB = -0.2; A.sobe = -0.09 * k - 0.03
		if n == 2:
			A.cA = 0.9; A.jA = -0.85; A.cB = -0.7; A.sobe = -0.2 * k; A.inc = -0.42 * k
		taxa = 90.0
	if J.is_empty():
		J = A.duplicate()
	var f := minf(1.0, dt * taxa)
	for kk in A:
		J[kk] += (A[kk] - J[kk]) * f
	N.quadril.position.y = QY + J.sobe * 0.6
	_rot(N.tronco, 0, J.tor, J.inc)
	_rot(N.cabeca, 0, -J.tor * 0.7, -J.inc * 0.6 + J.cab)
	_rot(N.cabeloTras, 0, 0, -vento * 0.14 + sin(r * 7 + 1) * 0.03 * vento + sin(r * 1.7 + 0.6) * 0.01)
	_rot(N.cabeloLongo, 0, 0, -0.1 - vento * 0.8 + sin(r * 7) * 0.06 * vento + sin(r * 1.7) * 0.03)
	_rot(N.ombroE, rest_x.ombroE, 0, J.S); _rot(N.cotoveloE, 0, 0, J.E)
	_rot(N.espadaBase, 0, 0, J.W)
	if N.has("armaExtra"):
		var w: Node3D = N.armaExtra
		if arma == "arco":
			w.rotation = Vector3(PI / 2, 0, J.W + 1.3)
		else:
			w.rotation = Vector3(0, 0, J.W)
	_rot(N.ombroS, rest_x.ombroS, 0, J.S2); _rot(N.cotoveloS, 0, 0, J.E2)
	_rot(N.escudoBase, 0, 0, -(J.S2 + J.E2) - J.inc)
	_rot(N.coxaA, rest_x.coxaA, 0, J.cA); _rot(N.joelhoA, 0, 0, J.jA)
	_rot(N.coxaB, rest_x.coxaB, 0, J.cB); _rot(N.joelhoB, 0, 0, J.jB)
	# piscar
	piscar -= dt
	if piscar <= 0:
		olho_fechado = 0.11; piscar = 2.5 + randf() * 3.0
	if olho_fechado > 0:
		olho_fechado -= dt
	if mat_rosto:
		mat_rosto.set_shader_parameter("tex", FECHADOS[nome] if olho_fechado > 0 else tex_aberto)

## Rotação na ordem do three.js (XYZ: matriz = Rx * Ry * Rz), mantendo a escala do nó.
func _rot(no: Node3D, x: float, y: float, z: float) -> void:
	no.basis = Basis(Vector3.RIGHT, x) * Basis(Vector3.UP, y) * Basis(Vector3.BACK, z) * Basis.from_scale(no.scale)
