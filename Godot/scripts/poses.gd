class_name Poses
extends RefCounted
## Poses do boneco (ângulos das juntas, ver boneco3d.gd). Em cada golpe, "pre" é a antecipação e "pos" é o
## fim do golpe; o boneco cuida do caminho entre as duas (acelera, passa do ponto e assenta).

const P := {
	# postura de luta: para onde o corpo volta depois de um golpe
	"pronto": {"S": 0.5, "E": 0.9, "W": -0.9, "S2": 0.6, "E2": 1.4, "inc": -0.1, "tor": 0.2, "cA": 0.45, "jA": -0.35, "cB": -0.45, "jB": -0.25, "sobe": -0.06},
	# ---- cortes de espada e de cajado ----
	# 1: corte diagonal de cima para baixo
	"corte1_pre": {"S": 2.7, "E": 0.9, "W": -0.5, "Sx": -0.35, "tor": -0.55, "inc": 0.14, "S2": 0.9, "E2": 1.3, "cA": 0.35, "jA": -0.3, "cB": -0.4, "jB": -0.3, "sobe": -0.04, "cab": -0.1, "dx": -0.04},
	"corte1_pos": {"S": 0.45, "E": 0.08, "W": -1.25, "Sx": 0.3, "tor": 0.55, "inc": -0.3, "S2": -0.5, "E2": 1.0, "cA": 0.75, "jA": -0.6, "cB": -0.6, "jB": -0.15, "sobe": -0.12, "cab": 0.15, "dx": 0.1},
	# 2: corte subindo, de baixo para cima
	"corte2_pre": {"S": -0.6, "E": 0.25, "W": -1.9, "Sx": 0.3, "tor": 0.6, "inc": -0.3, "S2": 0.2, "E2": 1.5, "cA": 0.7, "jA": -0.7, "cB": -0.5, "jB": -0.3, "sobe": -0.14},
	"corte2_pos": {"S": 2.5, "E": 0.15, "W": -1.1, "Sx": -0.3, "tor": -0.5, "inc": 0.16, "S2": -0.6, "E2": 0.9, "cA": 0.55, "jA": -0.25, "cB": -0.5, "jB": -0.1, "sobe": 0.02, "cab": -0.15, "dx": 0.06, "est": 0.04},
	# 3: estocada
	"corte3_pre": {"S": -0.2, "E": 1.9, "W": -1.75, "tor": -0.7, "inc": -0.05, "S2": 1.2, "E2": 0.5, "cA": 0.3, "jA": -0.4, "cB": -0.5, "jB": -0.4, "sobe": -0.1, "dx": -0.06},
	"corte3_pos": {"S": 1.5, "E": 0.05, "W": -1.5, "tor": 0.75, "inc": -0.28, "S2": -0.7, "E2": 0.6, "cA": 0.95, "jA": -0.8, "cB": -0.75, "jB": -0.05, "sobe": -0.16, "dx": 0.16, "cab": 0.2},
	# 4: golpe pesado por cima da cabeça
	"corte4_pre": {"S": 3.3, "E": 0.7, "W": -0.7, "Sx": -0.2, "tor": -0.3, "inc": 0.3, "S2": 2.6, "E2": 0.9, "cA": 0.3, "jA": -0.5, "cB": -0.35, "jB": -0.5, "sobe": 0.04, "cab": -0.2, "est": 0.08},
	"corte4_pos": {"S": 0.3, "E": 0.05, "W": -1.15, "tor": 0.35, "inc": -0.55, "S2": -0.4, "E2": 0.8, "cA": 1.0, "jA": -1.0, "cB": -0.8, "jB": -0.1, "sobe": -0.26, "cab": 0.3, "dx": 0.14, "est": -0.08},
	# ---- Guardião ----
	"lanca_pre": {"S": -0.9, "E": 0.2, "W": -1.5, "inc": -0.38, "sobe": -0.2, "cA": 0.95, "jA": -1.0, "cB": -0.5, "jB": -0.5, "tor": 0.5},
	"lanca_pos": {"S": 3.05, "E": 0.05, "W": -1.38, "inc": 0.2, "sobe": 0.06, "cA": 0.3, "jA": -0.1, "cB": -0.35, "tor": -0.4, "cab": -0.2, "est": 0.1},
	"escudo_pre": {"S2": 0.2, "E2": 1.9, "S": -0.6, "E": 0.6, "tor": -0.5, "inc": -0.1, "cA": 0.5, "cB": -0.4, "dx": -0.05},
	"escudo_pos": {"S2": 1.45, "E2": 0.25, "S": -0.9, "E": 0.4, "tor": 0.55, "inc": -0.32, "cA": 0.85, "jA": -0.7, "cB": -0.75, "jB": -0.1, "sobe": -0.1, "dx": 0.12},
	"mergulho": {"S": 0.75, "E": 0.05, "W": -0.35, "S2": -0.8, "E2": 0.6, "inc": -0.55, "cA": 0.9, "jA": -1.5, "cB": -0.1, "jB": -0.9, "sobe": 0.0, "est": 0.1},
	"guarda": {"S2": 1.3, "E2": 1.25, "S": -0.45, "E": 0.55, "inc": -0.12, "sobe": -0.14, "cA": 0.55, "jA": -0.7, "cB": -0.5, "jB": -0.4, "tor": 0.25},
	"giro": {"S": 1.55, "E": 0.02, "W": -1.38, "S2": -0.6, "E2": 0.8, "inc": -0.05, "cA": 0.4, "cB": -0.4, "sobe": -0.05},
	# ---- Caçadora ----
	"tiro_pre": {"S": 1.38, "E": 0.05, "W": -1.3, "S2": 1.1, "E2": 2.1, "tor": 0.6, "inc": 0.04, "sobe": -0.13, "cA": 0.75, "jA": -0.6, "cB": -0.6, "jB": -0.4},
	"tiro_pos": {"S": 1.42, "E": 0.0, "W": -1.3, "S2": 0.5, "E2": 0.7, "tor": 0.3, "inc": 0.08, "sobe": -0.12, "cA": 0.75, "jA": -0.6, "cB": -0.6, "jB": -0.4, "dx": -0.04},
	"tiro_baixo_pre": {"S": 0.9, "E": 0.05, "W": -1.3, "S2": 0.6, "E2": 1.9, "tor": 0.5, "inc": -0.25, "cA": 0.8, "jA": -1.2, "cB": -0.2, "jB": -0.8},
	"tiro_baixo_pos": {"S": 0.9, "E": 0.0, "W": -1.3, "S2": 0.3, "E2": 0.8, "tor": 0.3, "inc": -0.2, "cA": 0.8, "jA": -1.2, "cB": -0.2, "jB": -0.8},
	"chute_pre": {"cA": 0.5, "jA": -1.6, "inc": 0.1, "S": -0.5, "E": 0.5, "S2": -0.4, "E2": 0.8, "cB": -0.15, "jB": -0.1, "tor": -0.3},
	"chute_pos": {"cA": 1.55, "jA": -0.02, "inc": 0.32, "S": -0.8, "E": 0.3, "S2": -0.7, "E2": 0.4, "cB": -0.2, "jB": -0.05, "sobe": 0.02, "tor": 0.3, "dx": 0.06},
	"chute_alto": {"cA": 2.3, "jA": -0.02, "inc": 0.5, "S": -1.0, "E": 0.3, "S2": -0.9, "E2": 0.4, "cB": -0.1, "jB": -0.05, "sobe": 0.06, "cab": -0.2, "est": 0.06},
	"rasteira": {"cA": 1.35, "jA": -0.02, "inc": 0.55, "S": -1.1, "E": 0.2, "S2": -1.0, "E2": 0.3, "cB": -0.9, "jB": -1.6, "sobe": -0.42},
	# ---- Arcanista ----
	"conjura_pre": {"S": 2.5, "E": 0.5, "W": -1.2, "S2": 0.6, "E2": 1.4, "inc": 0.1, "cA": 0.3, "cB": -0.35, "tor": -0.3},
	"conjura_pos": {"S": 1.35, "E": 0.05, "W": -0.9, "S2": 1.2, "E2": 0.3, "inc": -0.15, "tor": 0.25, "cA": 0.6, "jA": -0.4, "cB": -0.55, "dx": 0.05},
	"pilar_pre": {"S": 0.5, "E": 0.3, "W": -1.5, "S2": 0.4, "E2": 0.6, "inc": -0.35, "sobe": -0.18, "cA": 0.8, "jA": -0.9, "cB": -0.5, "jB": -0.5},
	"pilar_pos": {"S": 2.9, "E": 0.05, "W": -1.38, "S2": 2.6, "E2": 0.1, "inc": 0.18, "sobe": 0.05, "cA": 0.25, "cB": -0.3, "cab": -0.25, "est": 0.08},
	# ---- todos ----
	"carga": {"S": 0.95, "E": 1.7, "W": -1.5, "S2": 0.9, "E2": 1.6, "inc": -0.16, "sobe": -0.12, "cA": 0.62, "jA": -0.7, "cB": -0.6, "jB": -0.35, "cab": 0.15},
	"vitoria": {"S": 3.0, "E": 0.08, "W": -1.38, "S2": 0.5, "E2": 1.5, "inc": 0.1, "cA": 0.3, "cB": -0.3, "cab": -0.2, "tor": -0.2},
	"furia": {"S": 0.35, "E": 1.0, "W": -0.45, "S2": 0.3, "E2": 1.2, "inc": 0.03, "tor": -0.15, "cab": 0.06, "cA": 0.4, "jA": -0.25, "cB": -0.4, "jB": -0.2},
}

## Cortes mostrados nas telas de menu (estado "atk" do boneco).
const CORTES := [["corte1_pre", "corte1_pos"], ["corte2_pre", "corte2_pos"], ["corte4_pre", "corte4_pos"]]
## Pernas encolhidas para os golpes no ar.
const NO_AR := {"cA": 0.95, "jA": -1.35, "cB": 0.15, "jB": -1.05, "sobe": 0.0, "dx": 0.0}

## Pose pelo nome; `no_ar` troca as pernas pelas de golpe aéreo.
static func pose(nome: String, no_ar := false) -> Dictionary:
	if not no_ar: return P[nome]
	var r: Dictionary = P[nome].duplicate()
	r.merge(NO_AR, true)
	return r
