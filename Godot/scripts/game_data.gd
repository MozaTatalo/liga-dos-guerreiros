class_name GameData
extends RefCounted
## Dados do jogo: classes, inimigos e fase. Ajuste números aqui para balancear.

const W := 480.0
const H := 270.0
const GROUND := 230.0
const LEVEL_W := 3150.0
const ATK_DUR := [16, 16, 24]
const ATK_HIT := [5, 5, 8]

const CLASSES := [
	{"id": "guardiao", "name": "Kael", "cls": "Guardião", "weapon": "Espada longa e escudo", "role": "Corpo a corpo · Equilibrado",
	 "desc": ["Linha de frente. Combos sólidos, investidas", "e golpes que lançam inimigos ao ar."],
	 "hp": 240, "mp": 100, "speed": 1.7, "body": "#2f5fbf", "dark": "#1d3c7a", "trim": "#e8c547", "hair": "#6b3a1f",
	 "skills": [{"n": "Investida de Escudo", "mp": 15, "cd": 180, "dur": 18, "c": "#e8c547"},
				{"n": "Corte Giratório", "mp": 30, "cd": 300, "dur": 36, "c": "#9fd3ff"},
				{"n": "Lâmina Ascendente", "mp": 20, "cd": 240, "dur": 26, "c": "#ffffff"}]},
	{"id": "cacadora", "name": "Lyra", "cls": "Caçadora", "weapon": "Arco longo", "role": "Distância · Mobilidade",
	 "desc": ["Ataca de longe, salta para trás e cobre", "a tela com chuva de flechas."],
	 "hp": 170, "mp": 120, "speed": 2.0, "body": "#2e7d4f", "dark": "#1f5c38", "trim": "#c9a26b", "hair": "#e0b04a",
	 "skills": [{"n": "Rajada Tripla", "mp": 15, "cd": 150, "dur": 20, "c": "#c9a26b"},
				{"n": "Salto Evasivo", "mp": 20, "cd": 240, "dur": 24, "c": "#ffd23f"},
				{"n": "Chuva de Flechas", "mp": 40, "cd": 420, "dur": 22, "c": "#8fe388"}]},
	{"id": "arcanista", "name": "Oren", "cls": "Arcanista", "weapon": "Cajado rúnico", "role": "Magia · Dano em área",
	 "desc": ["Frágil, mas devastador: orbes de fogo,", "raios em cadeia e meteoros."],
	 "hp": 150, "mp": 170, "speed": 1.55, "body": "#6a3fa0", "dark": "#45286b", "trim": "#59d0ff", "hair": "#d9d9e6",
	 "skills": [{"n": "Orbe Flamejante", "mp": 20, "cd": 150, "dur": 22, "c": "#ff8a3d"},
				{"n": "Corrente de Raios", "mp": 35, "cd": 300, "dur": 28, "c": "#9ff0ff"},
				{"n": "Meteoro", "mp": 55, "cd": 480, "dur": 30, "c": "#ff4d2e"}]},
]

const ENEMIES := {
	"lodo": {"w": 14, "h": 10, "hp": 45, "dmg": 8, "fly": false},
	"saqueador": {"w": 12, "h": 22, "hp": 80, "dmg": 10, "fly": false},
	"morcego": {"w": 12, "h": 8, "hp": 30, "dmg": 7, "fly": true},
	"atirador": {"w": 12, "h": 22, "hp": 60, "dmg": 8, "fly": false},
	"boss": {"w": 36, "h": 46, "hp": 1100, "dmg": 14, "fly": false},
}

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
