class_name GameData
extends RefCounted
## Dados do jogo: classes, inimigos, fases e dificuldades. Ajuste números aqui para balancear.

const VERSAO := "0.7"
const W := 480.0
const H := 270.0
const GROUND := 230.0
const LEVEL_W := 3150.0
const MANA_MAX := 3.0     # a barra de mana tem 3 níveis; cada nível solta uma habilidade

## stats: notas de 1 a 5 só para a tela de seleção.
## skills: habilidade do nível 1, 2 e 3 da barra de mana (segurar o ataque para carregar).
const CLASSES := [
	{"id": "guardiao", "name": "Kael", "cls": "Guardião", "weapon": "Espada longa e escudo", "role": "Corpo a corpo · Equilibrado",
	 "desc": ["Linha de frente da Ordem da Rosácea. Combos de espada,", "escudada que abre a guarda e golpes que lançam ao ar."],
	 "hp": 240, "speed": 1.75, "body": "#2f5fbf", "dark": "#1d3c7a", "trim": "#e8c547", "hair": "#6b3a1f",
	 "stats": {"Vida": 5, "Força": 4, "Alcance": 2, "Rapidez": 3},
	 "skills": [{"n": "Investida de Escudo", "dur": 20, "c": "#e8c547", "ico": "escudo", "d": "Avança com o escudo, atravessa e derruba."},
				{"n": "Lâmina Ascendente", "dur": 34, "c": "#bfe4ff", "ico": "ascendente", "d": "Sobe cortando e lança todos para o alto."},
				{"n": "Tempestade de Aço", "dur": 84, "c": "#9fd3ff", "ico": "giro", "d": "Gira a lâmina, puxa os inimigos e termina numa explosão."}]},
	{"id": "cacadora", "name": "Lyra", "cls": "Caçadora", "weapon": "Arco longo", "role": "Distância · Mobilidade",
	 "desc": ["Ataca de longe e nunca fica parada. Chutes que afastam,", "tiros no ar e uma chuva de flechas que cobre a tela."],
	 "hp": 170, "speed": 2.05, "body": "#2e7d4f", "dark": "#1f5c38", "trim": "#c9a26b", "hair": "#e0b04a",
	 "stats": {"Vida": 3, "Força": 3, "Alcance": 5, "Rapidez": 5},
	 "skills": [{"n": "Rajada Tripla", "dur": 22, "c": "#c9a26b", "ico": "tripla", "d": "Três flechas em leque."},
				{"n": "Flecha Perfurante", "dur": 28, "c": "#ffd23f", "ico": "perfurante", "d": "Salta para trás e dispara uma flecha que atravessa tudo."},
				{"n": "Chuva de Flechas", "dur": 40, "c": "#8fe388", "ico": "chuva", "d": "Dezenas de flechas caem numa área enorme."}]},
	{"id": "arcanista", "name": "Oren", "cls": "Arcanista", "weapon": "Cajado rúnico", "role": "Magia · Dano em área",
	 "desc": ["Frágil, mas devastador. Rajadas arcanas, pilares que", "lançam os inimigos e um meteoro que encerra a luta."],
	 "hp": 150, "speed": 1.6, "body": "#6a3fa0", "dark": "#45286b", "trim": "#59d0ff", "hair": "#d9d9e6",
	 "stats": {"Vida": 2, "Força": 5, "Alcance": 4, "Rapidez": 2},
	 "skills": [{"n": "Orbe Flamejante", "dur": 24, "c": "#ff8a3d", "ico": "orbe", "d": "Bola de fogo que explode no impacto."},
				{"n": "Corrente de Raios", "dur": 30, "c": "#9ff0ff", "ico": "raio", "d": "Um raio que salta entre até cinco inimigos."},
				{"n": "Meteoro", "dur": 44, "c": "#ff4d2e", "ico": "meteoro", "d": "Um meteoro cai do céu e devasta a área."}]},
]

## Fúria: enche batendo e apanhando. Com a barra cheia, A solta um golpe em área e deixa o herói desperto.
const FURIA_DUR := 600    # passos que o despertar dura (10 s)
const FURIA := {
	"guardiao": {"n": "Juramento da Rosácea", "c": "#ffd76a"},
	"cacadora": {"n": "Olho da Tempestade", "c": "#8fe388"},
	"arcanista": {"n": "Eclipse Arcano", "c": "#b58cff"},
}

## Personagens planejados, mostrados travados na seleção.
const FUTUROS := [{"name": "Brann", "cls": "Berserker", "weapon": "Machado de duas mãos"}]

const ENEMIES := {
	"lodo": {"nome": "Lodo", "w": 14, "h": 10, "hp": 45, "dmg": 8, "fly": false, "xp": 8, "ouro": 2, "peso": 0.9},
	"saqueador": {"nome": "Espectro", "w": 12, "h": 22, "hp": 80, "dmg": 10, "fly": false, "xp": 16, "ouro": 4, "peso": 1.0},
	"morcego": {"nome": "Morcego de Cinzas", "w": 12, "h": 8, "hp": 30, "dmg": 7, "fly": true, "xp": 7, "ouro": 2, "peso": 0.8},
	"atirador": {"nome": "Espectro Conjurador", "w": 12, "h": 22, "hp": 60, "dmg": 8, "fly": false, "xp": 14, "ouro": 4, "peso": 1.0},
	"boss": {"nome": "Espectro Ancião", "titulo": "Guardião das Ruínas", "w": 36, "h": 46, "hp": 1500, "dmg": 14, "fly": false, "xp": 260, "ouro": 120, "peso": 3.0},
}

const DIFS := [
	{"n": "Normal", "vida": 1.0, "dano": 1.0, "premio": 1.0, "c": "#8fe388"},
	{"n": "Difícil", "vida": 1.7, "dano": 1.5, "premio": 1.6, "c": "#ffb347"},
	{"n": "Pesadelo", "vida": 2.6, "dano": 2.2, "premio": 2.5, "c": "#ff4d5e"},
]

## Fases do primeiro mundo. Só as que têm "pronta" podem ser jogadas.
const FASES := [
	{"id": "arvalia", "n": "Ruínas de Arvália", "sub": "A catedral caída onde os espectros despertaram.", "chefe": "Espectro Ancião", "x": 70, "y": 176, "pronta": true},
	{"id": "cripta", "n": "Cripta dos Sussurros", "sub": "Corredores sob a catedral, cheios de ossos que andam.", "chefe": "?", "x": 150, "y": 128, "pronta": false},
	{"id": "floresta", "n": "Floresta Morta", "sub": "Árvores secas, névoa e algo que observa entre os galhos.", "chefe": "?", "x": 235, "y": 168, "pronta": false},
	{"id": "torre", "n": "Torre do Relógio", "sub": "Engrenagens gigantes e um sino que nunca para.", "chefe": "?", "x": 318, "y": 112, "pronta": false},
	{"id": "catedral", "n": "Catedral Afundada", "sub": "O coração da maldição de Arvália.", "chefe": "?", "x": 405, "y": 150, "pronta": false},
]

const RANKS_COMBO := [[10, "BOM", "#bfe4ff"], [25, "ÓTIMO", "#8fe388"], [45, "BRUTAL", "#ffb347"], [70, "IMPLACÁVEL", "#ff6b4a"], [100, "LENDÁRIO", "#ffd23f"]]

# Fase 1 — Ruínas de Arvália
const PLATS := [
	{"x": 300, "y": 186, "w": 70}, {"x": 640, "y": 182, "w": 80}, {"x": 1250, "y": 184, "w": 90},
	{"x": 1380, "y": 142, "w": 70}, {"x": 1600, "y": 180, "w": 100}, {"x": 1820, "y": 150, "w": 80},
	{"x": 2090, "y": 182, "w": 90}, {"x": 2170, "y": 138, "w": 70}, {"x": 2400, "y": 176, "w": 60}, {"x": 2620, "y": 176, "w": 60},
]
# [tipo, x, (altura da plataforma opcional)] por área
const SPAWNS := [
	[["lodo", 380], ["lodo", 430], ["saqueador", 560], ["lodo", 730], ["saqueador", 850], ["morcego", 900], ["saqueador", 980]],
	[["saqueador", 1180], ["atirador", 1290, 184], ["morcego", 1350], ["lodo", 1450], ["lodo", 1490], ["atirador", 1640, 180],
	 ["saqueador", 1720], ["morcego", 1780], ["morcego", 1840], ["saqueador", 1920], ["lodo", 2040], ["saqueador", 2100], ["atirador", 2195, 138]],
]
const BOSS_TRIGGER_X := 2360.0
const ARENA_L := 2300.0
const ARENA_R := 2780.0
const PORTAL_X := 3005.0
