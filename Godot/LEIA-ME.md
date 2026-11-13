# Liga dos Guerreiros (Godot 4)

## Como abrir
1. Instale o **Godot 4.5** (versão padrão, não a .NET): https://godotengine.org/download
2. Abra o Godot, clique em **Importar** e escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** para jogar.

## Controles
Setas: mover · X ou Espaço: pular (2x) · ↓ + X: descer da plataforma · Z: atacar (combo de 3)
C: esquiva · A / S / D: habilidades · P ou Esc: pausar · R: reiniciar · Enter: menu

## Organização
| Arquivo | O que faz |
|---|---|
| `scripts/game_data.gd` | Números do jogo: classes, habilidades, inimigos, plataformas e inimigos da fase |
| `scripts/hero.gd` | Personagem jogável: movimento, combo e habilidades de cada classe |
| `scripts/enemy.gd` | Inimigos e chefe (IA e desenho) |
| `scripts/game.gd` | A partida: lista de jogadores, golpes, projéteis, câmera, barreiras, portal |
| `scripts/player_input.gd` | De onde vêm os comandos de cada jogador (base para multijogador) |
| `scripts/gfx.gd` | Arte provisória desenhada em código (vai ser trocada pelos sprites) |
| `scripts/hud.gd`, `title.gd`, `world.gd`, `background.gd`, `fx_layer.gd` | Interface, título, cenário e efeitos |

## Preparado para multijogador
- O jogo trabalha com uma **lista de jogadores** (`game.players`). A IA mira o jogador mais próximo e a câmera segue o grupo.
- Cada herói lê comandos de um `PlayerInput` com prefixo próprio (`p1_`, `p2_`...). Para um 2º jogador local basta criar as ações `p2_*` no Mapa de Entrada e iniciar com duas classes, ex.: `start_game([0, 2])`.
- Para jogar online depois, uma subclasse de `PlayerInput` pode receber os comandos pela rede.
