# Liga dos Guerreiros (Godot 4)

## Como abrir
1. Instale o **Godot 4.5** (versão padrão, não a .NET): https://godotengine.org/download
2. Abra o Godot, clique em **Importar** e escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** para jogar.

## Controles
Setas: andar · → → (toque duplo): correr · X, Espaço ou ↑: pular (2x) · ↓ + X: descer da plataforma
Z: atacar (combo de 4) · ↓ + Z: lançador · correndo + Z: golpe de corrida · no ar: Z (3 golpes) e ↓ + Z (mergulho)
Segurar Z: carrega a mana (níveis 1, 2 e 3); soltar usa a habilidade · C: esquiva (Oren: teleporte) · A: Fúria com a barra cheia · segurar ↓: Kael defende · P ou Esc: pausa
Menus: setas escolhem, Z ou Enter confirma, C ou Esc volta.

## Organização
| Arquivo | O que faz |
|---|---|
| `scripts/game_data.gd` | Números do jogo: classes, habilidades, inimigos, fases, dificuldades |
| `scripts/hero.gd` | Personagem jogável: golpes de cada classe (tabela `GOLPES`), poses (`POSE`), carga de mana e habilidades |
| `scripts/enemy.gd` | Inimigos e chefe: IA e reações (lançado, caído) |
| `scripts/game.gd` | A partida: jogadores, golpes, projéteis, câmera, recompensas, pausa, resultado |
| `scripts/main.gd`, `menus.gd` | Fluxo do jogo e todos os menus (título, lobby, personagens, fases, golpes, opções) |
| `scripts/hud.gd` | Interface da fase, pausa, derrota e resultado |
| `scripts/ui.gd` | Peças da interface gótica: fontes, painéis, barras, botões, ícones, teclas |
| `scripts/save.gd` | Jogo salvo (`user://liga.json`) e opções |
| `scripts/som.gd` | Efeitos e música (autoload `Som`) |
| `scripts/player_input.gd` | De onde vêm os comandos de cada jogador (base para multijogador) |
| `scripts/cenario3d.gd` | Mapa gótico 3D atrás da fase, com a câmera 3D presa à câmera do jogo |
| `scripts/inimigo3d.gd`, `espectro3d.gd`, `lodo3d.gd`, `morcego3d.gd` | Corpos 3D dos inimigos |
| `scripts/boneco3d.gd`, `hero_view.gd` | Boneco 3D do herói (corpo base) e como ele aparece no jogo 2D |
| `scripts/gfx.gd`, `fx_layer.gd`, `world.gd` | Efeitos de golpe, projéteis, itens, barreiras e portal |
| `assets/fontes/` | Cinzel e Alegreya Sans (licença aberta OFL, textos das licenças na pasta) |
| `assets/som/` | Efeitos e músicas provisórios, gerados por `ferramentas/gerar_som.py` |
| `ferramentas/publicar.sh` | Gera a versão web e prepara os arquivos para publicar |
| `scenes/vitrine.tscn`, `vitrine_inimigos.tscn` | Cenas de teste dos bonecos e dos inimigos (F6) |

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
