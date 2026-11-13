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

func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = FOV
	cam.near = 0.3; cam.far = 260.0
	cam.position = Vector3(0, CENTRO_Y, _distancia())
	add_child(cam)
	cam.make_current()
	_ceu()
	var cena: Node3D = CENA.instantiate()
	add_child(cena)
	var brasas := PackedVector3Array()
	for m in cena.find_child("marcas", true, false).get_children():
		var p: Vector3 = m.position
		var nm := String(m.name)
		if nm.begins_with("brasa"):
			brasas.append(p)
			_brilho(p, Color("#ff7a2a"), 1.3, 0.85, true)
			_brilho(p + Vector3(0, -0.1, 0.01), Color("#ffd9a0"), 0.5, 0.95, true)
			_brilho(p + Vector3(0, 0.08, -0.01), Color("#ff6a20"), 4.5, 0.16, true)
		elif nm.begins_with("vitral"):
			_brilho(p, Color("#6a4fd0") if nm.begins_with("vitralA") else Color("#c43a5a"), 6.5, 0.1, false)
		elif nm.begins_with("vela"):
			_brilho(p, Color("#ffc070"), 0.4, 0.95, true)
	_juntar(cena, brasas)
	cena.queue_free()
	_nevoa()
	_cinzas()

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
	var r := RandomNumberGenerator.new(); r.seed = 7
	var x := -6.0
	while x < GameData.LEVEL_W / PX + 10:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new(); var s := r.randf_range(9, 15); qm.size = Vector2(s, s * 0.35)
		q.mesh = qm
		var m := ShaderMaterial.new(); m.shader = SH_NEVOA
		m.set_shader_parameter("cor", Color(0.52, 0.58, 0.77, r.randf_range(0.07, 0.12)))
		q.material_override = m
		q.position = Vector3(x, r.randf_range(0.5, 1.7), r.randf_range(-7, 2))
		add_child(q)
		nevoas.append({"no": q, "v": r.randf_range(0.15, 0.45), "x0": q.position.x})
		x += r.randf_range(4, 7)

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
	var t := Time.get_ticks_msec() / 1000.0
	for n in nevoas:
		n.no.position.x = n.x0 + fmod(t * n.v, 12.0) - 6.0
