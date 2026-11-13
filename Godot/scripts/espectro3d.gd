class_name Espectro3D
extends Inimigo3D
## Espectro do teste gótico: manto rasgado que ondula, capuz vazio com olhos e chama da alma no peito,
## mãos de osso que acendem antes do golpe e fiapos de névoa subindo da barra.

const CENA := preload("res://assets/inimigos/espectro.glb")
const TIPOS := {
	# escala, cor do manto, cor dos olhos/alma
	"saqueador": [0.82, Color("#232c5c"), Color("#6ff0ff")],
	"atirador": [0.78, Color("#3d1f66"), Color("#d08bff")],
	"boss": [1.75, Color("#4a1224"), Color("#ffb347")],
}

var tipo := "saqueador"
var corpo: Node3D
var braco_a: Node3D
var braco_b: Node3D
var giro := 0.0
var mats := []
var olhos := []
var halo: ShaderMaterial
var alma: ShaderMaterial
var garras := []
var nevoa: CPUParticles3D
var cor_olho: Color

func _init(k := "saqueador") -> void:
	tipo = k

func _ready() -> void:
	var cfg: Array = TIPOS.get(tipo, TIPOS.saqueador)
	cor_olho = cfg[2]
	var cena: Node3D = CENA.instantiate()
	add_child(cena)
	scale = Vector3.ONE * cfg[0]
	corpo = cena.find_child("corpo", true, false)
	braco_a = cena.find_child("bracoA", true, false)
	braco_b = cena.find_child("bracoB", true, false)
	for mi in cena.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).begins_with("ct_"):
			mi.material_override = contorno(float(String(mi.name).split("_")[1]) / 10000.0)
			continue
		var src = mi.mesh.surface_get_material(0)
		var nm := String(src.resource_name) if src else ""
		var c: Color = src.albedo_color if src is StandardMaterial3D else Color.BLACK
		if nm == "manto": c = cfg[1]
		elif nm == "mantoEsc": c = cfg[1].darkened(0.45)
		elif nm == "osso": c = Color("#d8cfb8")
		var m := toon(c)
		if nm == "vazio":
			m.set_shader_parameter("brilho", 0.0); m.set_shader_parameter("forca_aro", 0.0)
		if src is StandardMaterial3D and src.albedo_texture:
			m.set_shader_parameter("tex", src.albedo_texture); m.set_shader_parameter("tem_tex", true)
			m.set_shader_parameter("recorte", true)
		if nm == "manto" or nm == "mantoEsc":
			m.set_shader_parameter("onda", 0.045)
		m.set_shader_parameter("cor_aro", cfg[2].lerp(Color("#9a9cff"), 0.5))
		mi.material_override = m
		mats.append(m)
	for i in 2:
		var o: Node3D = cena.find_child("olho%d" % i, true, false)
		olhos.append(brilho(o, cor_olho, 0.24, 1.0))
		var nucleo := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.018; sm.height = 0.036; nucleo.mesh = sm
		var mn := StandardMaterial3D.new(); mn.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mn.albedo_color = cor_olho.lightened(0.6)
		nucleo.material_override = mn; o.add_child(nucleo)
	halo = brilho(corpo, cor_olho.darkened(0.2), 1.7, 0.22, Vector3(0.1, 1.5, 0))
	alma = brilho(corpo, cor_olho, 0.55, 0.55, Vector3(0.16, 1.05, 0.0))
	for b in [braco_a, braco_b]:
		garras.append(brilho(b, cor_olho, 0.4, 0.0, Vector3(0.03, -0.72, 0)))
	nevoa = fiapos(corpo, cor_olho.lerp(Color("#8a8cff"), 0.5), 14, 0.16, Vector3(0.3, 0.05, 0.3), Vector3(0, 0.05, 0), 0.5)
	fase = randf() * 10.0

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
	var olho := Color("#ff3b4e") if (furia or preparo > 0.5) else cor_olho
	var pulso := 0.5 + 0.5 * sin(fase * 6.0)
	for o in olhos:
		o.set_shader_parameter("cor", Color(olho.r, olho.g, olho.b, 1.0))
	halo.set_shader_parameter("cor", Color(olho.r, olho.g, olho.b, 0.2 + w * 0.06 + preparo * 0.3))
	alma.set_shader_parameter("cor", Color(olho.r, olho.g, olho.b, 0.35 + pulso * 0.25 + preparo * 0.3))
	for g in garras:
		g.set_shader_parameter("cor", Color(olho.r, olho.g, olho.b, preparo * 0.9))
	for m in mats:
		m.set_shader_parameter("flash", 1.0 if flash > 0 else 0.0)
	if morto > 0:
		morto += dt
		nevoa.emitting = false
		var s := maxf(0.001, 1.0 - morto * 1.5)
		corpo.scale = Vector3(s, 0.001 if morto > 0.66 else s, s)
		if morto > 1.4:
			queue_free()
