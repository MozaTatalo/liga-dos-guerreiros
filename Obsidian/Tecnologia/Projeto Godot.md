---
tags: [tecnologia, godot, multijogador]
versao: 0.3
---
# Projeto Godot

- **Pasta:** `B:\Antigravity\Liga Dos Guerreiros\Godot` (abrir `project.godot` no Godot 4.5, F5 para jogar)
- **Versão:** 0.3 (2026-11-13): heróis com os bonecos 3D do modelo base. 0.2 foi a migração completa do [[Protótipo]] HTML5
- **Jogar no navegador:** https://claude.ai/artifact/DbFEAxdA1fhGAuE5BqX7fa
- **Conteúdo:** [[Kael - Guardião]], [[Lyra - Caçadora]], [[Oren - Arcanista]] · [[Fase 1 - Ruínas de Arvália]] · [[Bestiário]] · controles em [[Combate]]
- **Resolução:** 480×270 ampliada (pixel art nítida), janela 1440×810, 60 passos fixos por segundo.

## Scripts
- `game_data.gd`: todos os números (classes, habilidades, inimigos, fase). Balanceamento é aqui.
- `hero.gd`: personagem, combo e habilidades. `enemy.gd`: inimigos e chefe.
- `game.gd`: partida, lista de jogadores, golpes, projéteis, câmera, barreiras, portal.
- `player_input.gd`: comandos por jogador (`p1_`, `p2_`...).
- `gfx.gd`: arte provisória em código (inimigos e cenário).
- `boneco3d.gd`: boneco 3D vindo do `kael.js` (glTF). Troca os materiais por cel-shading e contorno e anima as juntas com a mesma lógica do `posar()`.
- `hero_view.gd`: mostra o boneco no jogo 2D. SubViewport transparente com câmera ortográfica de lado (3/4), desenhado como sprite; espelha quando o herói vira.

## Bonecos 3D #arte
- Modelos em `assets/personagens/`: `kael.glb` (masculino, paleta 1), `lyra.glb` (feminino, paleta 3), `oren.glb` (masculino, paleta 2), só a base (macacão) e o cabelo; armadura e capa ainda não entram.
- Arma base de madeira por classe: espada e escudo (Kael, vêm do modelo), arco (Lyra) e cajado (Oren), estes dois feitos no `boneco3d.gd`.
- Contorno: cada peça guarda a espessura do `kael.js` no nome (`ct_<espessura>`); no jogo ela é dobrada para continuar legível no tamanho pequeno.
- Lyra ainda usa a cabeça do Kael como provisória (mesmo cabelo e rosto, outra cor).
- Para reexportar depois de mudar o `kael.js`: `Testes/2.5D/src/exportar/` (Node + Playwright, gera os `.glb` e a textura de olhos fechados).

## Multijogador #multijogador
Estrutura pronta: lista de jogadores, IA mira o mais próximo, câmera segue o grupo, entrada separada por jogador. Ver [[Engine e Plataforma]].

## Próximos passos #pendente
- Inimigos e cenário em 3D/2.5D no mesmo estilo dos heróis
- Armadura e equipamentos nos bonecos do jogo ([[Equipamentos]])
- Cabeça e rosto próprios da Lyra e do Oren
- Cooperativo local para 2 jogadores
- Sons e música
- 4º personagem: [[Brann - Berserker]]
