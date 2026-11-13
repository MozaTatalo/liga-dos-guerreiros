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
| `scripts/boneco3d.gd` | Boneco 3D (corpo base) vindo do `kael.js`: cel-shading, contorno e animação das juntas |
| `scripts/hero_view.gd` | Mostra o boneco 3D dentro do jogo 2D (SubViewport transparente desenhado como sprite) |
| `scenes/vitrine.tscn` | Cena de teste com os três bonecos grandes (abra e aperte F6) |
| `assets/personagens/` | Modelos `.glb` exportados do three.js e a textura do rosto de olhos fechados |
| `shaders/` | `toon.gdshader` (luz em degraus) e `contorno.gdshader` (casca invertida) |
| `scripts/gfx.gd` | Arte provisória desenhada em código (inimigos e cenário; os heróis já são 3D) |
| `scripts/hud.gd`, `title.gd`, `world.gd`, `background.gd`, `fx_layer.gd` | Interface, título, cenário e efeitos |

## Preparado para multijogador
- O jogo trabalha com uma **lista de jogadores** (`game.players`). A IA mira o jogador mais próximo e a câmera segue o grupo.
- Cada herói lê comandos de um `PlayerInput` com prefixo próprio (`p1_`, `p2_`...). Para um 2º jogador local basta criar as ações `p2_*` no Mapa de Entrada e iniciar com duas classes, ex.: `start_game([0, 2])`.
- Para jogar online depois, uma subclasse de `PlayerInput` pode receber os comandos pela rede.

## Bonecos 3D (versão 0.3)
Os heróis são os corpos base aprovados no `Testes/2.5D/src/kael.js`: Kael (corpo masculino, espada e escudo de madeira),
Lyra (corpo feminino, arco de madeira) e Oren (corpo masculino, cajado de madeira), cada um com uma paleta.
Para gerar os `.glb` de novo depois de mudar o `kael.js`: veja `Testes/2.5D/src/exportar/` (roda no Node com Playwright).

## Versão para navegador
Projeto > Exportar > Web (precisa dos modelos de exportação do Godot 4.5). Sai em `export/web/`.
