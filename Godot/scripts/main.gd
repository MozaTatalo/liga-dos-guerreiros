extends Node
## Raiz do jogo: alterna entre a tela de título e a partida.

const TitleScript := preload("res://scripts/title.gd")
const GameScript := preload("res://scripts/game.gd")

var bg
var current: Node
var last_sel := 0

func _ready() -> void:
	bg = Cenario3D.new()   # mapa gótico em 3D, atrás de tudo que é 2D
	add_child(bg)
	var moldura := CanvasLayer.new()   # cantos escurecidos por cima do jogo, por baixo da interface
	moldura.layer = 1
	var r := ColorRect.new()
	r.size = Vector2(GameData.W, GameData.H)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new(); m.shader = preload("res://shaders/vinheta.gdshader")
	r.material = m
	moldura.add_child(r)
	add_child(moldura)
	show_title()

func _clear() -> void:
	if current:
		current.queue_free()
		current = null

func show_title() -> void:
	_clear()
	var tt = TitleScript.new()
	tt.sel = last_sel
	tt.bg = bg
	tt.start_game.connect(func(idx): start_game.call_deferred(idx))
	add_child(tt)
	current = tt

func start_game(indexes: Array) -> void:
	_clear()
	last_sel = indexes[0]
	var g = GameScript.new()
	add_child(g)
	g.setup(indexes, bg)
	g.finished.connect(func(to_title, idx):
		if to_title:
			show_title.call_deferred()
		else:
			start_game.call_deferred(idx))
	current = g
