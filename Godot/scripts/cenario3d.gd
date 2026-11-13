class_name Cenario3D
extends Node3D
## Mapa gótico em 3D atrás da fase (ruínas de catedral, vitrais, arcada, braseiros, lápides, névoa e lua),
## exportado do teste gotico.html. A câmera 3D acompanha a câmera 2D do jogo: no plano z = 0 uma unidade
## vale exatamente PX pixels, então as plataformas 3D ficam onde estão as plataformas de colisão.

const PX := 26.0
const FOV := 28.0
const CENTRO_Y := (GameData.GROUND - GameData.H / 2.0) / PX
const SHADER := preload("res://shaders/cenario.gdshader")
const SH_CEU := preload("res://shaders/ceu.gdshader")
const SH_BRILHO := preload("res://shaders/brilho.gdshader")
const SH_NEVOA := preload("res://shaders/nevoa.gdshader")
const SH_ESTANDARTE := preload("res://shaders/estandarte.gdshader")
const SH_RAIO := preload("res://shaders/raio.gdshader")
const SH_SOMBRA := preload("res://shaders/sombra.gdshader")
const CENA := preload("res://assets/cenario/catedral.glb")
const CORES := {
	"pedra": Color("#4b4f62"), "pedraEsc": Color("#33364a"), "ferro": Color("#1c1d26"), "osso": Color("#bdb6a4"),
	"lado": Color("#20222c"), "longe": Color("#10131f"),
}

var cam_x := 0.0      # mesma câmera do jogo (px, canto esquerdo da tela)
var tremor := Vector2.ZERO
var chefe := 0.0
var cam: Camera3D
var mat_ceu: ShaderMaterial
var mats := []
var nevoas := []
var brasas := PackedVector3Array()
var sombras := {}     # dono -> MeshInstance3D
func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = FOV
	cam.near = 0.3; cam.far = 260.0
	cam.position = Vector3(0, CENTRO_Y, _distancia())
	add_child(cam)
	cam.make_current()
	_ambiente()
	_ceu()
	var cena: Node3D = CENA.instantiate()
	add_child(cena)
	for m in cena.find_child("marcas", true, false).get_children():
		var p: Vector3 = m.position
		var nm := String(m.name)
		if nm.begins_with("brasa"):
			brasas.append(p)
			_brilho(p, Color("#ff7a2a"), 1.3, 0.85, true)
			_brilho(p + Vector3(0, -0.1, 0.01), Color("#ffd9a0"), 0.5, 0.95, true)
			_brilho(p + Vector3(0, 0.08, -0.01), Color("#ff6a20"), 4.5, 0.16, true)
		elif nm.begins_with("vitral"):
			var cv := Color("#7a52ff") if nm.begins_with("vitralA") else Color("#ff3a78")
			_brilho(p, cv, 6.5, 0.14, false)
			_raio(p, cv)
		elif nm.begins_with("estandarte"):
			_estandarte(p)
		elif nm.begins_with("corrente"):
			_corrente(p)
		elif nm.begins_with("vela"):
			_brilho(p, Color("#ffc070"), 0.4, 0.95, true)
	_juntar(cena, brasas)
	self.brasas = brasas
	cena.queue_free()
	_nevoa()
	_cinzas()

## Brilho (bloom) nas luzes e um pouco mais de cor e contraste, no clima de anime.
func _ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.1
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.75
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.set_glow_level(1, 1.0); env.set_glow_level(2, 1.0); env.set_glow_level(3, 0.6); env.set_glow_level(4, 0.3)
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.22
	env.adjustment_contrast = 1.08
	env.adjustment_brightness = 1.04
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

## Feixe de luz do vitral até o chão, inclinado como luar entrando pela janela.
func _raio(p: Vector3, c: Color) -> void:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new(); qm.size = Vector2(2.2, 9.0)
	q.mesh = qm
	var m := ShaderMaterial.new(); m.shader = SH_RAIO
	m.set_shader_parameter("cor", Color(c.r, c.g, c.b, 0.16))
	q.material_override = m
	q.position = Vector3(p.x + 1.6, 2.4, p.z + 4.6)
	q.rotation = Vector3(-0.55, 0.0, 0.32)
	add_child(q)
	# poça de luz colorida no chão
	var poca := MeshInstance3D.new()
	var pm := QuadMesh.new(); pm.size = Vector2(3.2, 2.2)
	poca.mesh = pm
	var mp := ShaderMaterial.new(); mp.shader = SH_BRILHO
	mp.set_shader_parameter("cor", Color(c.r, c.g, c.b, 0.22)); mp.set_shader_parameter("forca", 1.0)
	poca.material_override = mp
	poca.position = Vector3(p.x + 2.6, 0.03, p.z + 8.2)
	add_child(poca)

## Estandarte rasgado da Ordem pendurado no pilar.
func _estandarte(p: Vector3) -> void:
	var q := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(0.95, 3.0); pm.subdivide_depth = 12; pm.orientation = PlaneMesh.FACE_Z
	q.mesh = pm
	var m := ShaderMaterial.new(); m.shader = SH_ESTANDARTE
	m.set_shader_parameter("fase", p.x * 0.9)
	q.material_override = m
	q.position = p + Vector3(0, -1.5, 0)
	add_child(q)
	var barra := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.035; cm.bottom_radius = 0.035; cm.height = 1.25
	barra.mesh = cm; barra.rotation.z = PI / 2; barra.position = p + Vector3(0, 0.02, 0)
	var mb := ShaderMaterial.new(); mb.shader = SHADER; mb.set_shader_parameter("cor", Color("#b8913f"))
	barra.material_override = mb
	add_child(barra)
	for sx in [-0.62, 0.62]:
		var b := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.06; sm.height = 0.12
		b.mesh = sm; b.material_override = mb; b.position = p + Vector3(sx, 0.02, 0); add_child(b)

## Corrente com lanterna no primeiro plano, pendurada do alto da tela (moldura e profundidade).
func _corrente(p: Vector3) -> void:
	var mf := ShaderMaterial.new(); mf.shader = SHADER; mf.set_shader_parameter("cor", Color("#191826"))
	mf.set_shader_parameter("forca_nevoa", 0.0)
	var topo := 9.5
	var fim := 6.6 + fmod(p.x * 0.37, 0.8)
	var y := topo
	var i := 0
	while y > fim:
		var elo := MeshInstance3D.new()
		var tm := TorusMesh.new(); tm.inner_radius = 0.05; tm.outer_radius = 0.09; tm.rings = 12; tm.ring_segments = 6
		elo.mesh = tm; elo.material_override = mf
		elo.position = Vector3(p.x, y, p.z)
		elo.rotation = Vector3(PI / 2, (PI / 2) * (i % 2), 0)
		add_child(elo)
		y -= 0.15; i += 1
	var lant := MeshInstance3D.new()
	var lm := CylinderMesh.new(); lm.top_radius = 0.12; lm.bottom_radius = 0.18; lm.height = 0.42; lm.radial_segments = 6
	lant.mesh = lm; lant.material_override = mf; lant.position = Vector3(p.x, fim - 0.3, p.z)
	add_child(lant)
	var g := _brilho(Vector3(p.x, fim - 0.3, p.z + 0.05), Color("#ffb45a"), 0.55, 0.95, true)
	g.get_parent()
	_brilho(Vector3(p.x, fim - 0.3, p.z + 0.04), Color("#ff7a2a"), 2.4, 0.22, true)

func _distancia() -> float:
	return (GameData.H / 2.0 / PX) / tan(deg_to_rad(FOV / 2.0))

## Junta todas as peças do mesmo material numa malha só (poucas chamadas de desenho, bom para o navegador).
func _juntar(cena: Node3D, brasas: PackedVector3Array) -> void:
	var grupos := {}
	var texs := {}
	for mi in cena.find_children("*", "MeshInstance3D", true, false):
		var src = mi.mesh.surface_get_material(0)
		var nm := String(src.resource_name) if src else "pedra"
		if not grupos.has(nm):
			grupos[nm] = SurfaceTool.new()
			grupos[nm].begin(Mesh.PRIMITIVE_TRIANGLES)
			if src is StandardMaterial3D and src.albedo_texture:
				texs[nm] = src.albedo_texture
		for s in mi.mesh.get_surface_count():
			grupos[nm].append_from(mi.mesh, s, cena.global_transform.affine_inverse() * mi.global_transform)
	for nm in grupos:
		var st: SurfaceTool = grupos[nm]
		var m := ShaderMaterial.new(); m.shader = SHADER
		m.set_shader_parameter("cor", CORES.get(nm, Color.WHITE))
		if texs.has(nm):
			m.set_shader_parameter("tex", texs[nm]); m.set_shader_parameter("tem_tex", true)
		if nm == "chao" or nm == "lado":
			m.set_shader_parameter("forca_aro", 0.0)   # sem brilho de borda no chão (ficava lavado)
			if nm == "chao": m.set_shader_parameter("cor", Color(0.78, 0.78, 0.82))
		if nm == "longe":
			m.set_shader_parameter("sem_luz", true)
		elif nm == "vitral":
			m.set_shader_parameter("sem_luz", true); m.set_shader_parameter("brilho_proprio", 1.25); m.set_shader_parameter("forca_nevoa", 0.55)
		m.set_shader_parameter("brasas", brasas)
		m.set_shader_parameter("n_brasas", mini(brasas.size(), 24))
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = 1000.0
		add_child(mi)
		mats.append(m)

func _brilho(p: Vector3, c: Color, escala: float, opac: float, treme: bool) -> MeshInstance3D:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new(); qm.size = Vector2.ONE * escala
	q.mesh = qm
	var m := ShaderMaterial.new(); m.shader = SH_BRILHO
	m.set_shader_parameter("cor", Color(c.r, c.g, c.b, opac))
	m.set_shader_parameter("forca", 1.6)
	m.set_shader_parameter("tremor", 1.0 if treme else 0.0)
	m.set_shader_parameter("fase", p.x * 1.7)
	q.material_override = m
	q.position = p
	add_child(q)
	return q

func _ceu() -> void:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new(); qm.size = Vector2(170, 85)
	q.mesh = qm
	mat_ceu = ShaderMaterial.new(); mat_ceu.shader = SH_CEU
	q.material_override = mat_ceu
	q.position = Vector3(0, 6, -150)
	cam.add_child(q)

func _nevoa() -> void:
	var larg := GameData.LEVEL_W / PX + 40
	for camada in [[-6.5, 2.4, Color(0.5, 0.45, 0.95, 0.28), 0.8, 0.05], [-1.5, 1.6, Color(0.6, 0.55, 1.0, 0.22), 1.1, 0.08], [2.8, 1.1, Color(0.62, 0.6, 1.0, 0.16), 1.4, 0.11]]:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new(); qm.size = Vector2(larg, camada[1])
		q.mesh = qm
		var m := ShaderMaterial.new(); m.shader = SH_NEVOA
		m.set_shader_parameter("cor", camada[2]); m.set_shader_parameter("escala", camada[3]); m.set_shader_parameter("vel", camada[4])
		q.material_override = m
		q.position = Vector3(larg / 2 - 20, camada[1] / 2 - 0.15, camada[0])
		q.extra_cull_margin = 1000.0
		add_child(q)

func _cinzas() -> void:
	var p := CPUParticles3D.new()
	p.amount = 90
	p.lifetime = 9.0
	p.preprocess = 9.0
	var qm := QuadMesh.new(); qm.size = Vector2(0.06, 0.06)
	var m := ShaderMaterial.new(); m.shader = SH_BRILHO
	m.set_shader_parameter("cor", Color(1.0, 0.69, 0.44, 0.9)); m.set_shader_parameter("forca", 2.0)
	qm.material = m
	p.mesh = qm
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(14, 0.5, 4)
	p.direction = Vector3(0.3, 1, 0)
	p.spread = 25.0
	p.gravity = Vector3(0, 0.05, 0)
	p.initial_velocity_min = 0.2; p.initial_velocity_max = 0.6
	p.position = Vector3(0, 0.3, -1)
	p.local_coords = false
	add_child(p)
	set_meta("cinzas", p)

## Chamado pelo jogo e pela tela de título a cada quadro.
func queue_redraw() -> void:
	var cx := (cam_x + GameData.W / 2.0 + tremor.x) / PX
	cam.position = Vector3(cx, CENTRO_Y - tremor.y / PX, _distancia())
	var cz: CPUParticles3D = get_meta("cinzas")
	cz.position.x = cx
	mat_ceu.set_shader_parameter("desloc", cam_x / PX)
	mat_ceu.set_shader_parameter("chefe", chefe)
	for m in mats:
		m.set_shader_parameter("tom", 1.0 - chefe * 0.25)

## Sombra macia no chão (ou na plataforma) embaixo de quem pede. px/py em pixels do jogo (pés).
func sombra(dono: Object, px: float, py: float, largura: float, vivo := true) -> void:
	var q: MeshInstance3D = sombras.get(dono)
	if not vivo:
		if q: q.queue_free(); sombras.erase(dono)
		return
	if q == null:
		q = MeshInstance3D.new()
		var pm := PlaneMesh.new(); pm.size = Vector2.ONE
		q.mesh = pm
		var m := ShaderMaterial.new(); m.shader = SH_SOMBRA
		q.material_override = m
		add_child(q)
		sombras[dono] = q
	var chao := GameData.GROUND
	for p in GameData.PLATS:
		if px >= p.x and px <= p.x + p.w and py <= p.y + 2 and p.y < chao:
			chao = p.y
	var alt := maxf(0.0, chao - py)
	var k := clampf(1.0 - alt / 90.0, 0.25, 1.0)
	q.position = Vector3(px / PX, (GameData.GROUND - chao) / PX + 0.02, 0.0)
	q.scale = Vector3(largura / PX * (0.6 + 0.4 * k), 1, largura / PX * 0.45)
	(q.material_override as ShaderMaterial).set_shader_parameter("forca", 0.6 * k)

## Braseiro mais próximo de um ponto (px) e a força da luz dele ali, para iluminar os bonecos.
func luz_braseiro(px: float, py: float) -> Vector4:
	var x := px / PX
	var y := (GameData.GROUND - py) / PX + 0.7
	var melhor := Vector4.ZERO
	for b in brasas:
		var d := Vector3(b.x - x, b.y - y, b.z - 0.0)
		var l := d.length()
		if l < 7.0:
			var f := pow(1.0 - l / 7.0, 1.4) * 1.1
			if f > melhor.w:
				melhor = Vector4(d.x / l, d.y / l, d.z / l, f)
	return melhor
