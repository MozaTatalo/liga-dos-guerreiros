extends Node
## Som do jogo (autoload "Som"): efeitos curtos e música de fundo. Os arquivos ficam em assets/som/.

const EFEITOS := ["golpe", "golpe2", "acerto", "acerto2", "critico", "pulo", "esquiva", "dano", "carga", "carga_nivel", "magia", "explosao",
	"flecha", "item", "moeda", "menu", "confirma", "volta", "nivel", "vitoria", "derrota", "chefe", "queda", "morte"]
var sons := {}
var canais: Array[AudioStreamPlayer] = []
var prox := 0
var musica: AudioStreamPlayer
var tocando := ""
var ultimo := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Save.d.is_empty(): Save.carregar()
	for nome in ["Musica", "Efeitos"]:
		AudioServer.add_bus(); AudioServer.set_bus_name(AudioServer.bus_count - 1, nome)
	for e in EFEITOS:
		var cam := "res://assets/som/%s.wav" % e
		if ResourceLoader.exists(cam): sons[e] = load(cam)
	for i in 12:
		var p := AudioStreamPlayer.new(); p.bus = "Efeitos"; add_child(p); canais.append(p)
	musica = AudioStreamPlayer.new(); musica.bus = "Musica"; add_child(musica)
	volumes()

func volumes() -> void:
	_vol("Musica", Save.op("musica") * 0.8); _vol("Efeitos", Save.op("efeitos"))

func _vol(bus: String, v: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_mute(i, v <= 0.01)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.01)))

func tocar(nome: String, vol := 1.0, tom := 1.0, variar := 0.06) -> void:
	if not sons.has(nome): return
	var agora := Time.get_ticks_msec()
	if agora - int(ultimo.get(nome, -999)) < 35: return   # evita o mesmo som empilhado no mesmo instante
	ultimo[nome] = agora
	var p := canais[prox]; prox = (prox + 1) % canais.size()
	p.stream = sons[nome]
	p.volume_db = linear_to_db(vol)
	p.pitch_scale = tom * randf_range(1.0 - variar, 1.0 + variar)
	p.play()

func tema(nome: String) -> void:
	if nome == tocando: return
	tocando = nome
	musica.stop()
	var cam := "res://assets/som/musica_%s.ogg" % nome
	if nome == "" or not ResourceLoader.exists(cam): return
	var s = load(cam)
	if s is AudioStreamOggVorbis: s.loop = true
	musica.stream = s
	musica.play()
