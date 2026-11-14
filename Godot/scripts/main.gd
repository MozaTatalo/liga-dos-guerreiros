extends Node
## Raiz do jogo: alterna entre os menus (título, lobby, seleções) e a partida.

const MenuScript := preload("res://scripts/menus.gd")
const GameScript := preload("res://scripts/game.gd")

var bg
var current: Node

func _ready() -> void:
	if Save.d.is_empty(): Save.carregar()
	Save.aplicar()
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
	var direto := OS.get_environment("LIGA_TESTE")   # só para testes: "jogo" pula os menus
	if direto.begins_with("jogo"): start_game()
	else: show_menu(direto if direto != "" else "titulo")

func _clear() -> void:
	if current:
		current.queue_free()
		current = null

func show_menu(tela := "lobby") -> void:
	_clear()
	var mn = MenuScript.new()
	mn.bg = bg
	mn.tela = tela
	mn.jogar.connect(func(): start_game.call_deferred())
	add_child(mn)
	current = mn

func start_game() -> void:
	_clear()
	var g = GameScript.new()
	add_child(g)
	g.setup([int(Save.d.sel)], bg, int(Save.d.fase), int(Save.d.dif))
	g.finished.connect(func(acao):
		if acao == "repetir": start_game.call_deferred()
		else: show_menu.call_deferred("lobby"))
	current = g
