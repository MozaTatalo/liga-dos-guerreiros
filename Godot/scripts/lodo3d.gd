class_name Lodo3D
extends Inimigo3D
## Lodo de ectoplasma: gosma translúcida que treme e estica nos pulos, com olhos acesos,
## ossinhos boiando dentro e gotas que sobem.

const SH := preload("res://shaders/ectoplasma.gdshader")
var corpo: Node3D
var gosma: ShaderMaterial
var olhos := []
var largura := 0.62

func _ready() -> void:
	corpo = Node3D.new(); add_child(corpo)
	var sm := SphereMesh.new(); sm.radius = 0.5; sm.height = 1.0; sm.radial_segments = 24; sm.rings = 14
	gosma = ShaderMaterial.new(); gosma.shader = SH
	gosma.set_shader_parameter("fase", randf() * 10.0)
	var b := peca(corpo, sm, gosma, Vector3(0, 0.5, 0))
	b.scale = Vector3(1.0, 0.78, 0.9)
	b.position.y = 0.38
	var ct := MeshInstance3D.new(); ct.mesh = sm; ct.material_override = contorno(0.02, 1.0); b.add_child(ct)
	# ossinhos boiando dentro
	var osso := toon(Color("#d8cfb8"))
	for i in 3:
		var cm := CapsuleMesh.new(); cm.radius = 0.03; cm.height = 0.2
		var o := peca(corpo, cm, osso, Vector3(-0.15 + i * 0.13, 0.22 + (i % 2) * 0.1, -0.05 + i * 0.03))
		o.rotation = Vector3(i * 0.9, i * 1.3, 0.6 + i)
	# olhos
	var branco := toon(Color("#f4f0ff")); branco.set_shader_parameter("forca_aro", 0.0)
	for sx in [-0.13, 0.13]:
		var em := SphereMesh.new(); em.radius = 0.075; em.height = 0.15
		peca(corpo, em, branco, Vector3(0.41, 0.5, sx), 0.012)
		olhos.append(brilho(corpo, Color("#7dffe8"), 0.22, 0.7, Vector3(0.47, 0.5, sx)))
		var pm := SphereMesh.new(); pm.radius = 0.035; pm.height = 0.07
		var pup := StandardMaterial3D.new(); pup.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; pup.albedo_color = Color("#0b1220")
		peca(corpo, pm, pup, Vector3(0.475, 0.5, sx))
	fiapos(corpo, Color("#5ef2d6"), 8, 0.1, Vector3(0.25, 0.1, 0.2), Vector3(0, 0.5, 0), 0.35)
	scale = Vector3.ONE * largura

func posar(dt: float) -> void:
	fase += dt
	flash = maxf(0.0, flash - dt)
	amasso = maxf(0.0, amasso - dt * 5.0)
	var alvo := -0.4 if lado > 0 else PI + 0.4
	rotation.y += (alvo - rotation.y) * 0.2
	var estica := 0.0
	if not no_chao:
		estica = clampf(-vy * 0.12, -0.3, 0.35)
	else:
		estica = sin(fase * 6.0) * 0.05 - amasso * 0.3
	corpo.scale = Vector3(1.0 - estica * 0.5, 1.0 + estica, 1.0 - estica * 0.5)
	gosma.set_shader_parameter("flash", 1.0 if flash > 0 else 0.0)
	gosma.set_shader_parameter("tremor", 1.0 + amasso * 3.0)
	if morto > 0:
		morto += dt
		corpo.scale = Vector3(1.0 + morto * 2.0, maxf(0.001, 1.0 - morto * 2.5), 1.0 + morto * 2.0)
		if morto > 0.5:
			queue_free()
