class_name HeroView
extends Node2D
## Mostra um Boneco3D dentro do jogo 2D: o boneco é renderizado num SubViewport transparente
## (câmera ortográfica de lado, 3/4 virado para a tela) e desenhado como um sprite.
## A origem deste nó fica nos pés do personagem.

const PX := 26.0        # pixels do jogo por unidade do modelo (o boneco tem ~1,5 de altura = ~38 px)
const CAMPO := 2.8      # tamanho da área renderizada, em unidades do modelo
const CENTRO_Y := 0.85  # altura do centro da câmera
const RES := 320        # resolução do SubViewport

var boneco: Boneco3D
var vp: SubViewport
var spr: Sprite2D
var virado := 1:
	set(v):
		virado = v
		if spr: spr.flip_h = v < 0

func _init(def: Dictionary) -> void:
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
	spr = Sprite2D.new()
	spr.texture = vp.get_texture()
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.scale = Vector2.ONE * (CAMPO * PX / RES)
	spr.position = Vector2(0, -CENTRO_Y * PX)
	spr.flip_h = virado < 0
	add_child(spr)

func animar(dt: float) -> void:
	boneco.posar(dt)
