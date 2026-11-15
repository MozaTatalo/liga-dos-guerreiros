class_name HeroView
extends Node2D
## Mostra um Boneco3D dentro do jogo 2D: o boneco é renderizado num SubViewport transparente
## (câmera ortográfica de lado, 3/4 virado para a tela) e desenhado como um sprite.
## A origem deste nó fica nos pés do personagem.

const SH_SPRITE := preload("res://shaders/heroi_sprite.gdshader")
const PX := 31.0        # pixels do jogo por unidade do modelo (o boneco tem ~1,5 de altura = ~46 px; herói em destaque, como nos jogos de ação anime)
const CAMPO := 2.8      # tamanho da área renderizada, em unidades do modelo
const CENTRO_Y := 0.85  # altura do centro da câmera
var RES := 384          # resolução do SubViewport (os menus pedem mais, para o herói grande)

var boneco: Boneco3D
var vp: SubViewport
var spr: Sprite2D
var cab0 := Vector3.INF   # posição da cabeça em repouso
var pisca_t := 0          # quadros piscando de vermelho (dano)
var fotos: Array = []     # janelas pequenas que guardam uma cópia do sprite, para as imagens fantasma
var foto_i := 0
var mat: ShaderMaterial   # luz de contorno pela silhueta, piscar e transparência do sprite
var virado := 1:
	set(v):
		virado = v
		if spr:
			spr.flip_h = v < 0
			mat.set_shader_parameter("lado", -1.0 if v < 0 else 1.0)

func _init(def: Dictionary, res := 384) -> void:
	RES = res
	var visual: Dictionary = MODELO.get(def.id, MODELO.guardiao)
	boneco = Boneco3D.new(visual.nome, visual.corpo, visual.arma)

const MODELO := {
	"guardiao": {"nome": "kael", "corpo": "m", "arma": "espada"},
	"cacadora": {"nome": "lyra", "corpo": "f", "arma": "arco"},
	"arcanista": {"nome": "oren", "corpo": "m", "arma": "cajado"},
}

func _ready() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(RES, RES)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var pivo := Node3D.new()
	pivo.rotation.y = -0.62  # 3/4: rosto virado um pouco para a câmera
	vp.add_child(pivo)
	pivo.add_child(boneco)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = CAMPO
	cam.position = Vector3(0, CENTRO_Y, 6)
	cam.near = 0.1; cam.far = 20
	vp.add_child(cam)
	cab0 = boneco.N.cabeca.global_position
	spr = Sprite2D.new()
	spr.texture = vp.get_texture()
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.scale = Vector2.ONE * (CAMPO * PX / float(RES))
	spr.position = Vector2(0, -CENTRO_Y * PX)
	spr.flip_h = virado < 0
	mat = ShaderMaterial.new(); mat.shader = SH_SPRITE
	mat.set_shader_parameter("lado", -1.0 if virado < 0 else 1.0)
	mat.set_shader_parameter("larg", 4.5 * RES / 384.0)
	spr.material = mat
	add_child(spr)

## Pinta o sprite inteiro de uma cor (força 0..1), para piscar ao levar dano.
func pisca(c: Color, forca: float) -> void:
	mat.set_shader_parameter("pisca", Color(c.r, c.g, c.b, forca))

func animar(dt: float) -> void:
	boneco.posar(dt)
	if pisca_t > 0:
		pisca_t -= 1
		pisca(Color(1.0, 0.25, 0.25), 0.75 if pisca_t % 4 >= 2 else 0.3)
		if pisca_t == 0: pisca(Color.WHITE, 0.0)

## Guarda uma cópia do sprite como está agora (cópia feita na placa de vídeo, sem custo de leitura) e devolve a textura.
func fotografar() -> Texture2D:
	if fotos.size() < 6:
		var f := SubViewport.new()
		f.size = Vector2i(RES / 2, RES / 2)
		f.transparent_bg = true
		f.disable_3d = true
		f.render_target_update_mode = SubViewport.UPDATE_DISABLED
		var r := TextureRect.new()
		r.texture = vp.get_texture()
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.size = Vector2(f.size)
		var m := CanvasItemMaterial.new(); m.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
		r.material = m
		f.add_child(r)
		add_child(f)
		fotos.append(f)
	foto_i = (foto_i + 1) % 6
	var alvo: SubViewport = fotos[mini(foto_i, fotos.size() - 1)]
	alvo.render_target_update_mode = SubViewport.UPDATE_ONCE
	return alvo.get_texture()

## Quanto a cabeça saiu do lugar de repouso, em UV da textura do boneco (o retrato da interface segue a cabeça).
func desvio_cabeca() -> Vector2:
	var p: Vector3 = boneco.N.cabeca.global_position
	if cab0 == Vector3.INF: cab0 = p
	return Vector2(p.x - cab0.x, cab0.y - p.y) / CAMPO

## Ponto do mundo do boneco -> posição em pixels do jogo, relativa aos pés do herói.
func para_jogo(p: Vector3) -> Vector2:
	return Vector2(p.x * PX * virado, -p.y * PX)
