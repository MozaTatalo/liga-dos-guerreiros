class_name Save
extends RefCounted
## Progresso guardado no computador (user://liga.json): nível e experiência por personagem, ouro, melhores resultados e opções.

const ARQ := "user://liga.json"
const NIVEL_MAX := 30
static var d := {}

static func padrao() -> Dictionary:
	return {"ouro": 0, "pers": {}, "fases": {}, "sel": 0, "fase": 0, "dif": 0,
		"op": {"musica": 0.7, "efeitos": 0.8, "tremor": true, "cheia": false}}

static func carregar() -> void:
	d = padrao()
	if FileAccess.file_exists(ARQ):
		var f := FileAccess.open(ARQ, FileAccess.READ)
		if f:
			var j = JSON.parse_string(f.get_as_text())
			if j is Dictionary:
				for k in j:
					if k == "op" and j[k] is Dictionary: d.op.merge(j[k], true)
					else: d[k] = j[k]

static func gravar() -> void:
	var f := FileAccess.open(ARQ, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d))

static func pers(id: String) -> Dictionary:
	if not d.pers.has(id): d.pers[id] = {"nivel": 1, "xp": 0}
	return d.pers[id]

static func nivel(id: String) -> int:
	return int(pers(id).nivel)

## Experiência necessária para sair do nível n.
static func xp_para(n: int) -> int:
	return 70 + 55 * n

static func mult_vida(n: int) -> float:
	return 1.0 + 0.08 * (n - 1)

static func mult_dano(n: int) -> float:
	return 1.0 + 0.06 * (n - 1)

## Guarda o resultado de uma fase; devolve true se foi recorde.
static func resultado(fase: String, dif: int, rank: String, tempo: float) -> bool:
	var chave := "%s:%d" % [fase, dif]
	var ordem := "CBAS"
	var ant = d.fases.get(chave)
	var melhor: bool = ant == null or ordem.find(rank) > ordem.find(ant.rank) or (rank == ant.rank and tempo < ant.tempo)
	if melhor: d.fases[chave] = {"rank": rank, "tempo": tempo}
	return melhor

static func feito(fase: String, dif: int):
	return d.fases.get("%s:%d" % [fase, dif])

static func op(k: String):
	return d.op[k]

# ---------------- Opções ----------------
const OPCOES := [["musica", "Música"], ["efeitos", "Efeitos"], ["tremor", "Tremor da tela"], ["cheia", "Tela cheia"]]

## Muda uma opção para um lado (-1 ou +1) e aplica na hora.
static func ajustar(chave: String, lado: int) -> void:
	if d.op[chave] is bool:
		d.op[chave] = not d.op[chave]
	else:
		d.op[chave] = clampf(snappedf(float(d.op[chave]) + lado * 0.1, 0.1), 0.0, 1.0)
	aplicar()
	gravar()

static func aplicar() -> void:
	Som.volumes()
	var cheia: bool = d.op.cheia
	var modo := DisplayServer.window_get_mode()
	if cheia and modo != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not cheia and modo == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

static func texto_op(chave: String) -> String:
	var v = d.op[chave]
	if v is bool: return "Sim" if v else "Não"
	return "%d%%" % int(roundf(float(v) * 100))
