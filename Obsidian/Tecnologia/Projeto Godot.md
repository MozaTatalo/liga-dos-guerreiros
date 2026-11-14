---
tags: [tecnologia, godot, multijogador]
versao: 0.6
---
# Projeto Godot

- **Pasta:** `B:\Antigravity\Liga Dos Guerreiros\Godot` (abrir `project.godot` no Godot 4.5, F5 para jogar)
- **Versão:** 0.6 (2026-11-14): combate de um botão com carga de mana, menus completos, HUD gótica, progressão, som. 0.5: polimento visual. 0.4: mapa gótico 3D e espectros. 0.3: heróis com os bonecos 3D. 0.2: migração do [[Protótipo]] HTML5
- **Jogar no navegador:** https://claude.ai/artifact/DbFEAxdA1fhGAuE5BqX7fa
- **Conteúdo:** [[Kael - Guardião]], [[Lyra - Caçadora]], [[Oren - Arcanista]] · [[Fase 1 - Ruínas de Arvália]] · [[Bestiário]] · [[Combate]] · [[Progressão]] · [[Interface e Menus]] · [[Áudio]]
- **Resolução:** base 480×270 ampliada com texto e formas nítidos, janela 1440×810, 60 passos fixos por segundo.

## Scripts
- `game_data.gd`: todos os números (classes, habilidades, inimigos, fases, dificuldades). Balanceamento é aqui.
- `hero.gd`: personagem. Tabela `GOLPES` (duração, quadro do acerto, golpe seguinte, animação) e `POSE` (ângulos das juntas de cada pose) por classe; carga de mana; habilidades.
- `enemy.gd`: inimigos e chefe, com as reações (lançado, quicando, caído, levantando).
- `game.gd`: partida, lista de jogadores, golpes, projéteis, câmera, barreiras, portal, experiência, ouro, pausa e resultado.
- `main.gd` e `menus.gd`: fluxo e menus (título, lobby, personagens, fases, golpes, opções).
- `hud.gd`: interface da fase. `ui.gd`: peças da interface (fontes, painéis, barras, ícones, teclas).
- `save.gd`: jogo salvo em `user://liga.json` e opções. `som.gd`: efeitos e música (autoload `Som`).
- `player_input.gd`: comandos por jogador (`p1_`, `p2_`...).
- `boneco3d.gd`: boneco 3D vindo do `kael.js` (glTF). Estado novo `livre`: quem usa o boneco passa os ângulos das juntas (é assim que os golpes novos são animados, sem mexer no corpo).
- `hero_view.gd`: mostra o boneco no jogo 2D; os menus pedem resolução maior para o herói grande.
- `ferramentas/gerar_som.py` (sons por síntese) e `ferramentas/publicar.sh` (versão web).

## Mapa e inimigos 3D #arte #mapa
- `cenario3d.gd` (substitui o antigo `background.gd`): carrega `assets/cenario/catedral.glb`, junta as peças por material (poucas chamadas de desenho), aplica `shaders/cenario.gdshader` (luz em degraus, luz dos braseiros, névoa) e cria céu (`ceu.gdshader`), chamas e halos (`brilho.gdshader`), névoa (`nevoa.gdshader`) e cinzas.
- A câmera 3D segue a câmera 2D: FOV 28°, distância calculada para que no plano z = 0 uma unidade valha 26 px. O 3D é desenhado atrás de tudo que é 2D.
- `inimigo3d.gd`: base dos inimigos 3D (`espectro3d.gd`, `lodo3d.gd`, `morcego3d.gd`). Lodo e Morcego são montados no próprio Godot.
- Brilho (bloom) e ajuste de cor no `WorldEnvironment` do `cenario3d.gd`; moldura escura em `shaders/vinheta.gdshader`; efeitos de golpe em `fx_layer.gd` (camada aditiva) e `Gfx.slash`/`Gfx.impacto`.
- `espectro3d.gd`: espectro do `gotico.html` (`assets/inimigos/espectro.glb`) para Saqueador, Atirador e chefe. O `enemy.gd` passa posição, lado, golpe recebido e preparo do ataque.
- O `world.gd` desenha só placa de início, barreiras e portal. Chão e plataformas são 3D; a colisão continua nos números do `game_data.gd`.

## Bonecos 3D #arte
- Modelos em `assets/personagens/`: `kael.glb` (masculino, paleta 1), `lyra.glb` (feminino, paleta 3), `oren.glb` (masculino, paleta 2), só a base (macacão) e o cabelo; armadura e capa ainda não entram.
- Arma base de madeira por classe: espada e escudo (Kael, vêm do modelo), arco (Lyra) e cajado (Oren), estes dois feitos no `boneco3d.gd`.
- Contorno: cada peça guarda a espessura do `kael.js` no nome (`ct_<espessura>`); no jogo ela é dobrada para continuar legível no tamanho pequeno.
- Lyra ainda usa a cabeça do Kael como provisória (mesmo cabelo e rosto, outra cor).
- Para reexportar depois de mudar o `kael.js`: `Testes/2.5D/src/exportar/` (Node + Playwright, gera os `.glb` e a textura de olhos fechados).

## Multijogador #multijogador
Estrutura pronta: lista de jogadores, IA mira o mais próximo, câmera segue o grupo, entrada separada por jogador. Ver [[Engine e Plataforma]].

## Próximos passos #pendente
Ver [[Roteiro de Versões]]. A seguir (v0.7): barra de Fúria, defesa do Kael, tutorial, fase 2 com salas e portais, introdução de chefe.
