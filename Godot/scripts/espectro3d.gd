class_name Espectro3D
extends Node3D
## Espectro do teste gótico: manto rasgado, capuz vazio com olhos que brilham e mãos de osso.
## Vive no mundo 3D (Cenario3D); o inimigo 2D só passa posição e estado.

const CENA := preload("res://assets/inimigos/espectro.glb")
const TOON := preload("res://shaders/toon.gdshader")
const CONTORNO := preload("res://shaders/contorno.gdshader")
const SH_BRILHO := preload("res://shaders/brilho.gdshader")
const TIPOS := {
	# escala, cor do manto, cor dos olhos
	"saqueador": [0.82, Color("#1d2433"), Color("#7fe9ff")],
	"atirador": [0.78, Color("#2b1d3a"), Color("#c58bff")],
	"boss": [1.75, Color("#2a1418"), Color("#ffb347")],
}

var tipo := "saqueador"
var lado := -1
var fase := 0.0
var flash := 0.0
var amasso := 0.0
var preparo := 0.0     # 0..1: braços erguidos antes do golpe
var furia := false     # chefe com pouca vida: olhos vermelhos
var morto := 0.0
var vx := 0.0
var corpo: Node3D
var braco_a: Node3D
var braco_b: Node3D
var giro := 0.0
var mats := []
var olhos := []
var halo: ShaderMaterial

func _init(k := "saqueador") -> void:
	tipo = k

func _ready() -> void:
	var cfg: Array = TIPOS.get(tipo, TIPOS.saqueador)
	var cena: Node3D = CENA.instantiate()
	add_child(cena)
	scale = Vector3.ONE * cfg[0]
	corpo = cena.find_child("corpo", true, false)
	braco_a = cena.find_child("bracoA", true, false)
	braco_b = cena.find_child("bracoB", true, false)
	for mi in cena.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).begins_with("ct_"):
			var mc := ShaderMaterial.new(); mc.shader = CONTORNO
			mc.set_shader_parameter("esp", float(String(mi.name).split("_")[1]) / 10000.0)
			mc.set_shader_parameter("escala", 1.6)
			mi.material_override = mc
			continue
		var src = mi.mesh.surface_get_material(0)
		var nm := String(src.resource_name) if src else ""
		var m := ShaderMaterial.new(); m.shader = TOON
		var c: Color = src.albedo_color if src is StandardMaterial3D else Color.BLACK
		if nm == "manto": c = cfg[1]
		elif nm == "mantoEsc": c = cfg[1].darkened(0.4)
		elif nm == "vazio": c = Color("#020205")
		m.set_shader_parameter("cor", c)
		if src is StandardMaterial3D and src.albedo_texture:
			m.set_shader_parameter("tex", src.albedo_texture); m.set_shader_parameter("tem_tex", true)
			m.set_shader_parameter("recorte", true)
		# luz da lua, igual ao cenário
		m.set_shader_parameter("cor_chave", Color("#a9bcff")); m.set_shader_parameter("forca_chave", 0.95)
		m.set_shader_parameter("ceu", Color("#6f7fb8")); m.set_shader_parameter("chao", Color("#15121c"))
		if nm == "vazio": m.set_shader_parameter("brilho", 0.0)
		mi.material_override = m
		mats.append(m)
	for i in 2:
		var o: Node3D = cena.find_child("olho%d" % i, true, false)
		olhos.append(_brilho(o, cfg[2], 0.2, 1.0))
		var nucleo := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.018; sm.height = 0.036; nucleo.mesh = sm
		var mn := StandardMaterial3D.new(); mn.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mn.albedo_color = cfg[2].lightened(0.5)
		nucleo.material_override = mn; o.add_child(nucleo)
	halo = _brilho(corpo, cfg[2].darkened(0.2), 1.6, 0.22)
	halo.get_meta("no").position = Vector3(0.1, 1.5, 0)
	fase = randf() * 10.0

func _brilho(pai: Node3D, c: Color, escala: float, opac: float) -> ShaderMaterial:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new(); qm.size = Vector2.ONE * escala
	q.mesh = qm
	var m := ShaderMaterial.new(); m.shader = SH_BRILHO
	m.set_shader_parameter("cor", Color(c.r, c.g, c.b, opac)); m.set_shader_parameter("forca", 1.6)
	q.material_override = m
	pai.add_child(q)
	m.set_meta("no", q)
	return m

## Mesma lógica do posarEspectro() do gotico.html, mais o preparo do golpe e a morte.
func posar(dt: float) -> void:
	fase += dt
	flash = maxf(0.0, flash - dt)
	amasso = maxf(0.0, amasso - dt * 5.0)
	var w := sin(fase * 2.2)
	var alvo := -0.35 if lado > 0 else PI + 0.35
	giro += (alvo - giro) * 0.15
	rotation.y = giro
	corpo.position.y = 0.3 + w * 0.08
	corpo.scale = Vector3(1 + amasso * 0.2, 1 - amasso * 0.22, 1 + amasso * 0.2)
	corpo.rotation.z = morto * 1.5 if morto > 0 else -absf(vx) * 0.05 + w * 0.03 - preparo * 0.15
	braco_a.rotation.z = 1.0 + w * 0.15 + preparo * 1.6
	braco_b.rotation.z = 0.8 - w * 0.15 + preparo * 1.2
	var olho := Color("#ff3b2e") if (furia or preparo > 0.5) else (TIPOS.get(tipo, TIPOS.saqueador)[2] as Color)
	for o in olhos:
		o.set_shader_parameter("cor", Color(olho.r, olho.g, olho.b, 1.0))
	halo.set_shader_parameter("cor", Color(olho.r, olho.g, olho.b, 0.2 + w * 0.06 + preparo * 0.25))
	for m in mats:
		m.set_shader_parameter("flash", 1.0 if flash > 0 else 0.0)
	if morto > 0:
		morto += dt
		var s := maxf(0.001, 1.0 - morto * 1.5)
		corpo.scale = Vector3(s, 0.001 if morto > 0.66 else s, s)
		if morto > 0.7:
			queue_free()

func morrer() -> void:
	morto = 0.001

func _process(dt: float) -> void:
	if morto > 0:   # o inimigo 2D já saiu de cena: a morte se anima sozinha
		posar(dt)
