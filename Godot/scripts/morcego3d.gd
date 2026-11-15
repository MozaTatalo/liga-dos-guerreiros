class_name Morcego3D
extends Inimigo3D
## Morcego de cinzas: corpo peludo escuro, orelhas pontudas, asas de membrana recortada que batem,
## olhos vermelhos acesos e brasas caindo das asas.

var corpo: Node3D
var asa_a: Node3D
var asa_b: Node3D
var mats := []

func _ready() -> void:
	corpo = Node3D.new(); add_child(corpo)
	var pelo := toon(Color("#2a2140")); mats.append(pelo)
	var membrana := toon(Color("#4a2a58")); mats.append(membrana)
	membrana.set_shader_parameter("forca_aro", 0.8)
	var sm := SphereMesh.new(); sm.radius = 0.16; sm.height = 0.36
	peca(corpo, sm, pelo, Vector3.ZERO, 0.012).scale = Vector3(0.9, 1.0, 0.85)
	var cab := SphereMesh.new(); cab.radius = 0.12; cab.height = 0.24
	var cb := peca(corpo, cab, pelo, Vector3(0.1, 0.2, 0), 0.012)
	for sz in [-0.06, 0.06]:
		var o := PrismMesh.new(); o.size = Vector3(0.07, 0.14, 0.03)
		peca(cb, o, pelo, Vector3(-0.02, 0.15, sz), 0.008).rotation.x = sz * 4.0
		brilho(cb, Color("#ff3048"), 0.14, 1.0, Vector3(0.11, 0.02, sz * 0.8))
	var presa := toon(Color("#f0e8dc"))
	for sz in [-0.025, 0.025]:
		var pr := PrismMesh.new(); pr.size = Vector3(0.02, 0.05, 0.02)
		peca(cb, pr, presa, Vector3(0.11, -0.07, sz)).rotation.z = PI
	asa_a = Node3D.new(); asa_a.position = Vector3(0, 0.05, 0.1); corpo.add_child(asa_a)
	asa_b = Node3D.new(); asa_b.position = Vector3(0, 0.05, -0.1); corpo.add_child(asa_b)
	var malha := _asa()
	peca(asa_a, malha, membrana, Vector3.ZERO, 0.01)
	var mb := peca(asa_b, malha, membrana, Vector3.ZERO, 0.01)
	mb.scale.z = -1
	fiapos(corpo, Color("#ff8a3c"), 6, 0.05, Vector3(0.3, 0.05, 0.3), Vector3(0, -0.05, 0), -0.6)
	scale = Vector3.ONE * 1.25

## Asa de membrana: dedos longos e a borda de trás recortada em arcos.
func _asa() -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dedos := [Vector3(0.14, 0.14, 0.3), Vector3(0.06, 0.12, 0.58), Vector3(-0.08, 0.06, 0.66), Vector3(-0.2, -0.02, 0.5)]
	var raiz := Vector3(0, 0, 0)
	var corpo_tras := Vector3(-0.16, -0.05, 0.02)
	var pontos := [Vector3(0.08, 0.02, 0.02)]
	pontos.append_array(dedos)
	pontos.append(corpo_tras)
	for i in pontos.size() - 1:
		var a: Vector3 = pontos[i]
		var b: Vector3 = pontos[i + 1]
		var meio := (a + b) * 0.5
		var rec := meio.lerp(raiz, 0.13) if i > 0 else meio
		for v in [raiz, a, rec, raiz, rec, b]:
			st.set_normal(Vector3(0, 1, 0)); st.add_vertex(v)
	st.generate_normals()
	return st.commit()

func posar(dt: float) -> void:
	fase += dt
	flash = maxf(0.0, flash - dt)
	var alvo := -0.9 if lado > 0 else PI + 0.9
	rotation.y += (alvo - rotation.y) * 0.2
	var bate := sin(fase * 16.0)
	asa_a.rotation.x = -0.2 + bate * 0.9
	asa_b.rotation.x = 0.2 - bate * 0.9
	corpo.position.y = bate * 0.04
	corpo.rotation.z = -0.15 + preparo * 0.5
	for m in mats:
		m.set_shader_parameter("flash", 1.0 if flash > 0 else 0.0)
	if morto > 0:
		morto += dt
		corpo.rotation.x += dt * 12.0
		position.y -= dt * 2.0
		scale = Vector3.ONE * maxf(0.001, 1.25 * (1.0 - morto * 1.5))
		if morto > 0.65:
			queue_free()
