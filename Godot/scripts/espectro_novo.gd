class_name EspectroNovo
extends Inimigo3D
## Espectro v0.9: monge caído da catedral, modelado no Blender (ferramentas/blender/espectro.py) como uma
## malha só com esqueleto, textura pintada e animações feitas à mão: parado, andar, preparo, golpe, dor e morte.
## O enemy.gd passa o estado do golpe; aqui só se escolhe a animação e se acendem os brilhos.

const CENA := preload("res://assets/inimigos/espectro_novo.glb")
const TIPOS := {
	# escala, textura, cor dos olhos/alma
	"saqueador": [0.86, "res://assets/inimigos/espectro_novo_saqueador.png", Color("#6ff0ff")],
	"atirador": [0.82, "res://assets/inimigos/espectro_novo_atirador.png", Color("#d08bff")],
}
const ALTURA := 0.38      # a barra rasgada fica abaixo da origem: sobe o corpo para flutuar

var tipo := "saqueador"
var anim: AnimationPlayer
var corpo: Node3D
var mat: ShaderMaterial
var olhos := []
var alma: ShaderMaterial
var halo: ShaderMaterial
var garras := []
var nevoa: CPUParticles3D
var cor_olho: Color
var giro := 0.0
var atual := ""
var estado_ant := ""

func _init(k := "saqueador") -> void:
	tipo = k

func _ready() -> void:
	add_to_group("corpo_inimigo")
	var cfg: Array = TIPOS.get(tipo, TIPOS.saqueador)
	cor_olho = cfg[2]
	corpo = CENA.instantiate()
	add_child(corpo)
	corpo.position.y = ALTURA
	scale = Vector3.ONE * cfg[0]
	var tex: Texture2D = load(cfg[1]) if ResourceLoader.exists(cfg[1]) else load(TIPOS.saqueador[1])
	mat = toon(Color.WHITE)
	mat.set_shader_parameter("tex", tex); mat.set_shader_parameter("tem_tex", true)
	mat.set_shader_parameter("cor_aro", cor_olho.lerp(Color("#9a9cff"), 0.5))
	mat.set_shader_parameter("forca_aro", 1.1)
	mat.set_shader_parameter("brilho", 1.3)
	mat.set_shader_parameter("tinta_sombra", Color(0.5, 0.48, 0.8))
	mat.next_pass = contorno(0.006, 1.6)
	for mi in corpo.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = mat
	anim = corpo.find_child("AnimationPlayer", true, false)
	for nome in ["parado", "andar", "preparo"]:
		if anim.has_animation(nome):
			anim.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
	for i in 2:
		var o: Node3D = corpo.find_child("olho%d" % i, true, false)
		if o:
			olhos.append(brilho(o, cor_olho, 0.2, 1.0))
	var a: Node3D = corpo.find_child("alma", true, false)
	if a:
		alma = brilho(a, cor_olho, 0.5, 0.45)
		halo = brilho(a, cor_olho.darkened(0.2), 1.6, 0.16, Vector3(0, 0.35, 0))
	for n in ["garraR", "garraL"]:
		var g: Node3D = corpo.find_child(n, true, false)
		if g:
			garras.append(brilho(g, cor_olho, 0.45, 0.0))
	nevoa = fiapos(self, cor_olho.lerp(Color("#8a8cff"), 0.5), 16, 0.14, Vector3(0.25, 0.05, 0.25), Vector3(0, 0.15, 0), 0.5)
	fase = randf() * 10.0
	_tocar("parado", 0.0)
	anim.seek(randf() * 1.5, true)

func _tocar(nome: String, mistura := 0.12, vel := 1.0) -> void:
	if nome == atual and anim.is_playing():
		anim.speed_scale = vel
		return
	atual = nome
	anim.play(nome, mistura)
	anim.speed_scale = vel

## O visual mudou (tecla V): o enemy.gd recria o corpo na próxima atualização.
func trocar_visual() -> void:
	pass

func posar(dt: float) -> void:
	fase += dt
	flash = maxf(0.0, flash - dt)
	var levou := amasso > 0.4
	amasso = maxf(0.0, amasso - dt * 5.0)
	var alvo_giro := -0.35 if lado > 0 else PI + 0.35
	giro += (alvo_giro - giro) * 0.15
	rotation.y = giro
	if morto > 0:
		morto += dt
		_tocar("morte", 0.08)
		nevoa.emitting = false
		var k := clampf((morto - 0.7) / 0.7, 0.0, 1.0)
		mat.set_shader_parameter("brilho", 1.3 * (1.0 - k * 0.8))
		for o in olhos: o.set_shader_parameter("cor", Color(cor_olho.r, cor_olho.g, cor_olho.b, 1.0 - k))
		if alma: alma.set_shader_parameter("cor", Color(cor_olho.r, cor_olho.g, cor_olho.b, 0.5 * (1.0 - k)))
		if halo: halo.set_shader_parameter("cor", Color(cor_olho.r, cor_olho.g, cor_olho.b, 0.0))
		scale = scale.lerp(Vector3(scale.x, 0.001, scale.z), k * 0.08)
		if morto > 1.45:
			queue_free()
		return
	var prep := estado in ["windup", "aim"]
	var saiu_do_preparo := estado_ant in ["windup", "aim"] and not prep
	estado_ant = estado
	if estado in ["launched", "down"] or (levou and not prep):
		if levou or atual != "dor":
			atual = ""
		_tocar("dor", 0.05)
	elif prep:
		_tocar("preparo", 0.1)
	elif saiu_do_preparo or (atual == "golpe" and anim.is_playing()):
		_tocar("golpe", 0.02)
	elif atual == "dor" and anim.is_playing():
		pass
	elif absf(vx) > 0.15:
		_tocar("andar", 0.25, clampf(absf(vx) * 1.2, 0.7, 1.6))
	else:
		_tocar("parado", 0.3)
	var olho := Color("#ff3b4e") if (furia or preparo > 0.5) else cor_olho
	var pulso := 0.5 + 0.5 * sin(fase * 6.0)
	for o in olhos:
		o.set_shader_parameter("cor", Color(olho.r, olho.g, olho.b, 1.0))
	if alma: alma.set_shader_parameter("cor", Color(olho.r, olho.g, olho.b, 0.3 + pulso * 0.2 + preparo * 0.3))
	if halo: halo.set_shader_parameter("cor", Color(olho.r, olho.g, olho.b, 0.12 + preparo * 0.25))
	for g in garras:
		g.set_shader_parameter("cor", Color(olho.r, olho.g, olho.b, preparo * 0.9))
	mat.set_shader_parameter("flash", 1.0 if flash > 0 else 0.0)
