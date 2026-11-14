class_name Inimigo3D
extends Node3D
## Base dos inimigos 3D que vivem no Cenario3D. O inimigo 2D (enemy.gd) cuida da regra do jogo
## e só passa posição e estado; aqui fica a aparência e a animação.

const TOON := preload("res://shaders/toon.gdshader")
const CONTORNO := preload("res://shaders/contorno.gdshader")
const SH_BRILHO := preload("res://shaders/brilho.gdshader")

var lado := -1
var fase := 0.0
var flash := 0.0
var amasso := 0.0
var preparo := 0.0     # 0..1: preparando o golpe
var furia := false
var morto := 0.0
var vx := 0.0
var vy := 0.0
var no_chao := true

func posar(_dt: float) -> void:
	pass

func morrer() -> void:
	morto = 0.001

func _process(dt: float) -> void:
	if morto > 0:   # o inimigo 2D já saiu de cena: a morte se anima sozinha
		posar(dt)

## Material de cel-shading com a luz da lua do cenário.
func toon(c: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new(); m.shader = TOON
	m.set_shader_parameter("cor", c)
	m.set_shader_parameter("cor_chave", Color("#b3b8ff")); m.set_shader_parameter("forca_chave", 0.95)
	m.set_shader_parameter("ceu", Color("#7378d0")); m.set_shader_parameter("chao", Color("#1d1226"))
	m.set_shader_parameter("forca_aro", 0.6)
	return m

func contorno(esp: float, escala := 1.6) -> ShaderMaterial:
	var mc := ShaderMaterial.new(); mc.shader = CONTORNO
	mc.set_shader_parameter("esp", esp); mc.set_shader_parameter("escala", escala)
	return mc

## Malha com contorno por casca invertida.
func peca(pai: Node3D, mesh: Mesh, mat: Material, pos := Vector3.ZERO, esp := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = mat; mi.position = pos
	pai.add_child(mi)
	if esp > 0:
		var ct := MeshInstance3D.new(); ct.mesh = mesh; ct.material_override = contorno(esp); mi.add_child(ct)
	return mi

func brilho(pai: Node3D, c: Color, escala: float, opac: float, pos := Vector3.ZERO) -> ShaderMaterial:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new(); qm.size = Vector2.ONE * escala
	q.mesh = qm
	var m := ShaderMaterial.new(); m.shader = SH_BRILHO
	m.set_shader_parameter("cor", Color(c.r, c.g, c.b, opac)); m.set_shader_parameter("forca", 1.6)
	q.material_override = m
	q.position = pos
	pai.add_child(q)
	m.set_meta("no", q)
	return m

## Fiapos que sobem (névoa da alma, gotas de ectoplasma...).
func fiapos(pai: Node3D, c: Color, qtd: int, tam: float, caixa: Vector3, pos: Vector3, sobe := 0.4) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = qtd; p.lifetime = 1.4
	var qm := QuadMesh.new(); qm.size = Vector2.ONE * tam
	var m := ShaderMaterial.new(); m.shader = SH_BRILHO
	m.set_shader_parameter("cor", Color(c.r, c.g, c.b, 0.7)); m.set_shader_parameter("forca", 1.4)
	qm.material = m
	p.mesh = qm
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = caixa
	p.direction = Vector3(0, 1, 0); p.spread = 30.0
	p.gravity = Vector3(0, sobe, 0)
	p.initial_velocity_min = 0.05; p.initial_velocity_max = 0.25
	p.scale_amount_min = 0.5; p.scale_amount_max = 1.2
	var curva := Curve.new(); curva.add_point(Vector2(0, 0.2)); curva.add_point(Vector2(0.3, 1.0)); curva.add_point(Vector2(1, 0.0))
	p.scale_amount_curve = curva
	p.local_coords = false
	p.position = pos
	pai.add_child(p)
	return p
